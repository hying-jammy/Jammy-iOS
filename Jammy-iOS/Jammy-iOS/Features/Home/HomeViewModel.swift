import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    struct FeaturedRow: Identifiable {
        let id: Int
        let title: String
        let meta: String
        let statusTitle: String
        let statusKind: JammyChip.Kind
        let capsuleTitle: String
        let capsuleSubtitle: String
        let dDay: String
    }

    struct Row: Identifiable {
        let id: Int
        let title: String
        let meta: String
        let statusTitle: String
        let statusKind: JammyChip.Kind
        let tone: PhotoPlaceholder.Tone
    }

    enum State {
        case idle
        case loading
        case loaded
        case failed(AppError)
    }

    private(set) var state: State = .idle
    private(set) var nickname = ""
    private(set) var featured: FeaturedRow?
    private(set) var rows: [Row] = []
    private(set) var totalCount = 0

    private let authRepository: AuthRepository
    private let roomRepository: RoomRepository
    private let dateProvider: DateProvider

    init(authRepository: AuthRepository, roomRepository: RoomRepository, dateProvider: DateProvider) {
        self.authRepository = authRepository
        self.roomRepository = roomRepository
        self.dateProvider = dateProvider
    }

    var isEmpty: Bool { totalCount == 0 }

    func load() async {
        // 이미 불러온 적이 있으면 로딩 화면을 다시 보여주지 않고 조용히 갱신한다.
        if case .idle = state { state = .loading }
        do {
            nickname = await authRepository.currentUser()?.nickname ?? ""
            let rooms = try await roomRepository.fetchMyRooms()
            apply(rooms)
            state = .loaded
        } catch {
            state = .failed(AppError(error))
        }
    }

    func logout() async {
        await authRepository.logout()
    }

    // MARK: - 화면용 데이터 만들기

    private func apply(_ rooms: [TripRoom]) {
        let now = dateProvider.now
        totalCount = rooms.count

        let featuredRoom = rooms.first { room in
            room.capsule?.status(at: now) == .locked && isOngoing(room, now: now)
        }
        featured = featuredRoom.flatMap { makeFeatured($0, now: now) }

        let tones: [PhotoPlaceholder.Tone] = [.pink, .sunny, .green]
        rows = rooms
            .filter { $0.id != featuredRoom?.id }
            .enumerated()
            .map { index, room in
                let status = status(for: room, now: now)
                return Row(
                    id: room.id,
                    title: room.title,
                    meta: meta(for: room),
                    statusTitle: status.title,
                    statusKind: status.kind,
                    tone: tones[index % tones.count]
                )
            }
    }

    private func makeFeatured(_ room: TripRoom, now: Date) -> FeaturedRow? {
        guard let capsule = room.capsule else { return nil }
        let status = status(for: room, now: now)
        return FeaturedRow(
            id: room.id,
            title: room.title,
            meta: meta(for: room),
            statusTitle: status.title,
            statusKind: status.kind,
            capsuleTitle: "타임캡슐 잠금 중",
            capsuleSubtitle: "\(JammyDate.monthDay(capsule.openAt)) \(JammyDate.time(capsule.openAt)) 공개",
            dDay: Countdown(from: now, to: capsule.openAt).dDayText
        )
    }

    private func meta(for room: TripRoom) -> String {
        "\(JammyDate.range(room.startDate, room.endDate)) · \(room.memberCount)명"
    }

    private func isOngoing(_ room: TripRoom, now: Date) -> Bool {
        now >= room.startDate && now <= room.endDate
    }

    private func status(for room: TripRoom, now: Date) -> (title: String, kind: JammyChip.Kind) {
        if room.capsule?.status(at: now) == .opened { return ("열림", .green) }
        if isOngoing(room, now: now) { return ("여행 중", .solid) }
        if now < room.startDate { return ("예정", .neutral) }
        return ("잠금", .yellow)
    }
}
