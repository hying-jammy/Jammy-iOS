import Foundation
import Observation

@MainActor
@Observable
final class CapsuleDetailViewModel {
    struct EntryItem: Identifiable {
        let id: Int
        let author: Member
        let text: String
        let photoURL: URL?
        let photoData: Data?
    }

    struct Loaded {
        let info: CapsuleInfo
        /// 공개 후에만 채워진다.
        let entries: [DiaryEntry]
    }

    enum State {
        case loading
        case loaded(Loaded)
        case failed(AppError)
    }

    let roomID: Int
    private(set) var state: State = .loading
    /// 카운트다운 표시에 쓰는 현재 시각. `tick()` 으로 갱신한다.
    private(set) var now: Date

    private let capsuleRepository: CapsuleRepository
    private let diaryRepository: DiaryRepository
    private let dateProvider: DateProvider
    private var lastReload: Date?

    init(roomID: Int, capsuleRepository: CapsuleRepository, diaryRepository: DiaryRepository, dateProvider: DateProvider) {
        self.roomID = roomID
        self.capsuleRepository = capsuleRepository
        self.diaryRepository = diaryRepository
        self.dateProvider = dateProvider
        self.now = dateProvider.now
    }

    var loaded: Loaded? {
        if case .loaded(let loaded) = state { return loaded }
        return nil
    }

    var info: CapsuleInfo? { loaded?.info }

    /// 공개 여부는 서버 판단을 따른다.
    var isOpened: Bool { info?.isOpened ?? false }

    var title: String { info?.title ?? "" }

    var countdown: Countdown? {
        info.map { Countdown(from: now, to: $0.openAt) }
    }

    var openAtText: String {
        guard let info else { return "" }
        return "\(JammyDate.monthDayWeekday(info.openAt)) \(JammyDate.time(info.openAt)) 공개 예정"
    }

    var openedSubtitle: String {
        guard let info else { return "" }
        return "\(info.title) · \(info.members.count)명이 함께 열었어요"
    }

    var memberRows: [MemberProgress] { info?.members ?? [] }

    var entryItems: [EntryItem] {
        (loaded?.entries ?? []).map {
            EntryItem(id: $0.id, author: Member(nickname: $0.authorNickname), text: $0.text, photoURL: $0.photoURL, photoData: $0.photoData)
        }
    }

    func load() async {
        do {
            let info = try await capsuleRepository.fetchCapsule(roomID: roomID)
            var entries: [DiaryEntry] = []
            if info.isOpened {
                do {
                    entries = try await diaryRepository.fetchCapsuleDiaries(roomID: roomID)
                } catch AppError.capsuleNotOpened {
                    entries = []
                }
            }
            state = .loaded(Loaded(info: info, entries: entries))
            lastReload = dateProvider.now
        } catch {
            state = .failed(AppError(error))
        }
    }

    /// 1초마다 호출된다. 공개 시각이 지났는데 서버가 아직 잠금이라면 몇 초 간격으로 다시 확인한다.
    func tick() async {
        now = dateProvider.now
        guard let info, !info.isOpened, now >= info.openAt else { return }
        if let lastReload, now.timeIntervalSince(lastReload) < 3 { return }
        await load()
    }
}
