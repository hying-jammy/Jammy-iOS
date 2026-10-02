import Foundation

/// 타임캡슐. MVP 에서는 방당 1개.
struct TimeCapsule: Identifiable, Hashable {
    enum Status { case locked, opened }

    let id: UUID
    var title: String
    var openAt: Date

    /// 공개 여부는 저장하지 않고 시각으로 계산한다. (서버 연동 시 서버 시각 기준으로 교체)
    func status(at now: Date) -> Status {
        now >= openAt ? .opened : .locked
    }
}

/// 타임캡슐 상세 화면에 필요한 데이터.
struct CapsuleDetail: Hashable {
    var room: TripRoom
    var capsule: TimeCapsule
    /// 비밀 일기를 이미 작성한 참여자
    var submittedMemberIDs: Set<UUID>
    /// 공개 후에만 채워진다. 공개 전에는 항상 빈 배열.
    var entries: [DiaryEntry]
}
