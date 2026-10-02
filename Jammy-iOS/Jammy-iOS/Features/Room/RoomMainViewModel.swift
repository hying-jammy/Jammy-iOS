import Foundation
import Observation

@MainActor
@Observable
final class RoomMainViewModel {
    struct FeedItem: Identifiable {
        let id: UUID
        let author: Member?
        let timeText: String
        let text: String
        let photoData: Data?
    }

    struct TimelineItem: Identifiable {
        let id: UUID
        let authorName: String
        let isCapsule: Bool
        let text: String
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

    let roomID: UUID
    var tab: RoomTab = .feed
    private(set) var state: State = .loading
    private(set) var room: TripRoom?
    private(set) var feedItems: [FeedItem] = []
    private(set) var timelineSections: [TimelineSection] = []
    private(set) var capsuleSummary: CapsuleSummary?

    private let roomRepository: RoomRepository
    private let diaryRepository: DiaryRepository
    private let dateProvider: DateProvider

    init(roomID: UUID, roomRepository: RoomRepository, diaryRepository: DiaryRepository, dateProvider: DateProvider) {
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
            async let timelineResult = diaryRepository.fetchTimeline(roomID: roomID)
            let (room, feed, timeline) = try await (roomResult, feedResult, timelineResult)

            self.room = room
            apply(room: room, feed: feed, timeline: timeline)
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    // MARK: - 화면용 데이터 만들기

    private func apply(room: TripRoom, feed: [DiaryEntry], timeline: [DiaryEntry]) {
        let now = dateProvider.now
        let calendar = Calendar.current

        feedItems = feed.map { entry in
            FeedItem(
                id: entry.id,
                author: room.member(id: entry.authorID),
                timeText: JammyDate.relative(entry.createdAt, to: now),
                text: entry.text,
                photoData: entry.photoData.first
            )
        }

        let grouped = Dictionary(grouping: timeline) { calendar.startOfDay(for: $0.createdAt) }
        timelineSections = grouped.keys.sorted().map { day in
            let entries = grouped[day] ?? []
            return TimelineSection(
                id: day,
                title: JammyDate.monthDayWeekday(day),
                countText: "\(entries.count)개",
                items: entries.map { entry in
                    TimelineItem(
                        id: entry.id,
                        authorName: room.member(id: entry.authorID)?.nickname ?? "알 수 없음",
                        isCapsule: entry.visibility == .capsule,
                        text: entry.text,
                        photoData: entry.photoData.first
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
