import Foundation

struct TripRoom: Identifiable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    /// 예: "JAM-4F7K"
    var inviteCode: String
    var ownerID: UUID
    var members: [Member]
    var maxMembers: Int
    var capsule: TimeCapsule?

    var isFull: Bool { members.count >= maxMembers }

    func member(id: UUID) -> Member? {
        members.first { $0.id == id }
    }
}

struct NewRoomDraft {
    var title: String
    var startDate: Date
    var endDate: Date
    var maxMembers: Int
    var capsuleOpenAt: Date
}
