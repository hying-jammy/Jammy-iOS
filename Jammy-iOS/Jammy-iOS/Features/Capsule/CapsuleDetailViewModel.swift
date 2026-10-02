import Foundation
import Observation

@MainActor
@Observable
final class CapsuleDetailViewModel {
    struct MemberRow: Identifiable {
        let member: Member
        let hasSubmitted: Bool
        var id: UUID { member.id }
    }

    struct EntryItem: Identifiable {
        let id: UUID
        let author: Member?
        let text: String
    }

    enum State {
        case loading
        case loaded(CapsuleDetail)
        case failed(AppError)
    }

    let roomID: UUID
    private(set) var state: State = .loading
    /// 카운트다운/공개 전환 판단에 쓰는 현재 시각. `tick()` 으로 갱신한다.
    private(set) var now: Date

    private let capsuleRepository: CapsuleRepository
    private let dateProvider: DateProvider

    init(roomID: UUID, capsuleRepository: CapsuleRepository, dateProvider: DateProvider) {
        self.roomID = roomID
        self.capsuleRepository = capsuleRepository
        self.dateProvider = dateProvider
        self.now = dateProvider.now
    }

    var detail: CapsuleDetail? {
        if case .loaded(let detail) = state { return detail }
        return nil
    }

    var isOpened: Bool {
        detail?.capsule.status(at: now) == .opened
    }

    var countdown: Countdown? {
        detail.map { Countdown(from: now, to: $0.capsule.openAt) }
    }

    var openAtText: String {
        guard let capsule = detail?.capsule else { return "" }
        return "\(JammyDate.monthDayWeekday(capsule.openAt)) \(JammyDate.time(capsule.openAt)) 공개 예정"
    }

    var openedSubtitle: String {
        guard let detail else { return "" }
        return "\(detail.capsule.title) · \(detail.room.members.count)명이 함께 열었어요"
    }

    var memberRows: [MemberRow] {
        guard let detail else { return [] }
        return detail.room.members.map {
            MemberRow(member: $0, hasSubmitted: detail.submittedMemberIDs.contains($0.id))
        }
    }

    var entryItems: [EntryItem] {
        guard let detail else { return [] }
        return detail.entries.map { EntryItem(id: $0.id, author: detail.room.member(id: $0.authorID), text: $0.text) }
    }

    func load() async {
        do {
            state = .loaded(try await capsuleRepository.fetchCapsuleDetail(roomID: roomID))
        } catch {
            state = .failed(AppError(error))
        }
    }

    /// 1초마다 호출된다. 공개 시각이 지나면 열린 기록을 불러온다.
    func tick() async {
        let wasLocked = !isOpened
        now = dateProvider.now
        if wasLocked, isOpened { await load() }
    }
}
