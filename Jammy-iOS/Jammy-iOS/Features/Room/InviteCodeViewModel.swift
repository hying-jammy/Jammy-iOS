import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class InviteCodeViewModel {
    let room: TripRoom
    private(set) var didCopy = false

    init(room: TripRoom) {
        self.room = room
    }

    func copyCode() async {
        UIPasteboard.general.string = room.inviteCode
        didCopy = true
        try? await Task.sleep(for: .seconds(2))
        didCopy = false
    }

    var shareText: String {
        "Jammy에서 '\(room.title)' 방에 함께해요! 초대 코드: \(room.inviteCode)"
    }

    var capsuleText: String? {
        guard let capsule = room.capsule else { return nil }
        return "타임캡슐 \(JammyDate.monthDayWeekday(capsule.openAt)) \(JammyDate.time(capsule.openAt)) 공개"
    }

    var metaText: String {
        var text = "\(room.title) · \(JammyDate.range(room.startDate, room.endDate))"
        if let limit = room.memberLimit { text += " · 최대 \(limit)명" }
        return text
    }

    var memberCountText: String {
        if let limit = room.memberLimit { return "\(room.memberCount) / \(limit)" }
        return "\(room.memberCount)"
    }

    /// 아직 비어 있는 자리 수 (점선 슬롯)
    var emptySlotCount: Int {
        guard let limit = room.memberLimit else { return 0 }
        return max(0, limit - room.memberCount)
    }
}
