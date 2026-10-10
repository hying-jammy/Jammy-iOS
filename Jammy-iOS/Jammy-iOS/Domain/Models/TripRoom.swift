import Foundation

struct TripRoom: Identifiable, Hashable {
    let id: Int
    var title: String
    var startDate: Date
    var endDate: Date
    /// 예: "JAM-4F7K"
    var inviteCode: String
    /// 목록 API 는 참여자 목록을 주지 않으므로 비어 있을 수 있다. 인원 수는 `memberCount` 를 쓴다.
    var members: [Member]
    var memberCount: Int
    /// 방 상세/목록 API 는 최대 인원을 주지 않는다. (생성·초대 코드 확인 응답에만 있음)
    var memberLimit: Int?
    var capsule: TimeCapsule?

    var isFull: Bool {
        memberLimit.map { memberCount >= $0 } ?? false
    }
}

struct NewRoomDraft {
    var title: String
    var startDate: Date
    var endDate: Date
    var memberLimit: Int
    var capsuleOpenAt: Date
}
