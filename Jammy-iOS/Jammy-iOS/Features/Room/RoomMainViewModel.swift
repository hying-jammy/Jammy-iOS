import Foundation
import Observation

@MainActor
@Observable
final class RoomMainViewModel {
    struct FeedItem: Identifiable {
        let id: Int
        let author: Member
        let timeText: String
        /// 비밀 일기(타임캡슐)면 내용을 담지 않고 가림 표시만 한다.
        let isSecret: Bool
        let text: String
        let photoURL: URL?
        let photoData: Data?
    }

    struct TimelineItem: Identifiable {
        let id: Int
        let authorName: String
        let isCapsule: Bool
        /// 아직 공개되지 않은 비밀 일기. 내용은 비어 있다.
        let isHidden: Bool
        let text: String
        let photoURL: URL?
        let photoData: Data?
    }

    struct TimelineSection: Identifiable {
        let id: Date
        let title: String
        let countText: String
        let items: [TimelineItem]
    }

    struct CapsuleSummary {
        let title: String
        let subtitle: String
        let isOpened: Bool
    }

    enum State {
        case loading
        case loaded
        case failed(AppError)
    }

    let roomID: Int
    var tab: RoomTab = .feed
    private(set) var state: State = .loading
    private(set) var room: TripRoom?
    private(set) var feedItems: [FeedItem] = []
    private(set) var timelineSections: [TimelineSection] = []
    private(set) var capsuleSummary: CapsuleSummary?

    private let roomRepository: RoomRepository
    private let diaryRepository: DiaryRepository
    private let dateProvider: DateProvider

    init(roomID: Int, roomRepository: RoomRepository, diaryRepository: DiaryRepository, dateProvider: DateProvider) {
        self.roomID = roomID
        self.roomRepository = roomRepository
        self.diaryRepository = diaryRepository
        self.dateProvider = dateProvider
    }

    var metaText: String {
        guard let room else { return "" }
        return JammyDate.range(room.startDate, room.endDate)
    }

    var membersText: String {
        room?.members.map(\.nickname).joined(separator: ", ") ?? ""
    }

    func load() async {
        do {
            async let roomResult = roomRepository.fetchRoom(id: roomID)
            async let feedResult = diaryRepository.fetchFeed(roomID: roomID)
            let (room, feed) = try await (roomResult, feedResult)

            // 기록 탭: 공개 일기 + (타임캡슐이 열렸다면) 타임캡슐 일기.
            // 서버는 공개 전 타임캡슐 일기를 내려주지 않는다.
            var capsuleDiaries: [DiaryEntry] = []
            if room.capsule?.status(at: dateProvider.now) == .opened {
                do {
                    capsuleDiaries = try await diaryRepository.fetchCapsuleDiaries(roomID: roomID)
                } catch AppError.capsuleNotOpened {
                    capsuleDiaries = []
                }
            }

            self.room = room
            apply(room: room, feed: feed, capsuleDiaries: capsuleDiaries)
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    // MARK: - 화면용 데이터 만들기

    private func apply(room: TripRoom, feed: [DiaryEntry], capsuleDiaries: [DiaryEntry]) {
        let now = dateProvider.now
        let calendar = Calendar.current

        // 공개 피드에는 서버가 비밀 일기도 내려주므로, 비밀 일기는 내용(글/사진)을 아예 버리고 가림 표시만 남긴다.
        feedItems = feed.map { entry in
            let isSecret = entry.visibility == .capsule
            return FeedItem(
                id: entry.id,
                author: Member(nickname: entry.authorNickname),
                timeText: JammyDate.relative(entry.createdAt, to: now),
                isSecret: isSecret,
                text: isSecret ? "" : entry.text,
                photoURL: isSecret ? nil : entry.photoURL,
                photoData: isSecret ? nil : entry.photoData
            )
        }

        // 기록 탭: 공개 일기 + 열린 타임캡슐 일기. 아직 공개되지 않은 비밀 일기는 내용을 가린 채 함께 보여준다.
        let revealedIDs = Set(capsuleDiaries.map(\.id))
        let hiddenSecrets = feed.filter { $0.visibility == .capsule && !revealedIDs.contains($0.id) }
        let hiddenIDs = Set(hiddenSecrets.map(\.id))
        let publicEntries = feed.filter { $0.visibility == .friends }
        let timeline = (publicEntries + capsuleDiaries + hiddenSecrets).sorted { $0.createdAt < $1.createdAt }
        let grouped = Dictionary(grouping: timeline) { calendar.startOfDay(for: $0.createdAt) }
        timelineSections = grouped.keys.sorted().map { day in
            let entries = grouped[day] ?? []
            return TimelineSection(
                id: day,
                title: JammyDate.monthDayWeekday(day),
                countText: "\(entries.count)개",
                items: entries.map { entry in
                    let isHidden = hiddenIDs.contains(entry.id)
                    return TimelineItem(
                        id: entry.id,
                        authorName: entry.authorNickname,
                        isCapsule: entry.visibility == .capsule,
                        isHidden: isHidden,
                        text: isHidden ? "" : entry.text,
                        photoURL: isHidden ? nil : entry.photoURL,
                        photoData: isHidden ? nil : entry.photoData
                    )
                }
            )
        }

        capsuleSummary = room.capsule.map { capsule in
            let isOpened = capsule.status(at: now) == .opened
            let subtitle: String
            if isOpened {
                subtitle = "모두의 비밀 기록이 열렸어요"
            } else {
                let dDay = Countdown(from: now, to: capsule.openAt).dDayText
                subtitle = "\(JammyDate.monthDay(capsule.openAt)) \(JammyDate.time(capsule.openAt)) 공개 · \(dDay)"
            }
            return CapsuleSummary(title: capsule.title, subtitle: subtitle, isOpened: isOpened)
        }
    }
}
