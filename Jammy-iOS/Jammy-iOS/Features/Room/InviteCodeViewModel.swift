import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class InviteCodeViewModel {
    enum State {
        case loading
        case loaded(TripRoom)
        case failed(AppError)
    }

    let roomID: UUID
    private(set) var state: State = .loading
    private(set) var didCopy = false

    private let roomRepository: RoomRepository

    init(roomID: UUID, roomRepository: RoomRepository) {
        self.roomID = roomID
        self.roomRepository = roomRepository
    }

    func load() async {
        do {
            state = .loaded(try await roomRepository.fetchRoom(id: roomID))
        } catch {
            state = .failed(AppError(error))
        }
    }

    func copyCode(_ room: TripRoom) async {
        UIPasteboard.general.string = room.inviteCode
        didCopy = true
        try? await Task.sleep(for: .seconds(2))
        didCopy = false
    }

    func shareText(for room: TripRoom) -> String {
        "Jammy에서 '\(room.title)' 방에 함께해요! 초대 코드: \(room.inviteCode)"
    }

    func capsuleText(for room: TripRoom) -> String? {
        guard let capsule = room.capsule else { return nil }
        return "타임캡슐 \(JammyDate.monthDayWeekday(capsule.openAt)) \(JammyDate.time(capsule.openAt)) 공개"
    }

    func metaText(for room: TripRoom) -> String {
        "\(room.title) · \(JammyDate.range(room.startDate, room.endDate)) · 최대 \(room.maxMembers)명"
    }
}
