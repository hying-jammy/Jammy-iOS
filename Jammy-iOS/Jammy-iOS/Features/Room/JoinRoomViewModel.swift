import Foundation
import Observation

@MainActor
@Observable
final class JoinRoomViewModel {
    enum LookupState: Equatable {
        case idle
        case checking
        case found(TripRoom)
        case failed(String)
    }

    var code = "" {
        didSet {
            guard code != oldValue else { return }
            formatCode()
        }
    }
    private(set) var lookupState: LookupState = .idle
    private(set) var isJoining = false
    private(set) var joinErrorMessage: String?

    private let roomRepository: RoomRepository

    init(roomRepository: RoomRepository) {
        self.roomRepository = roomRepository
    }

    /// "JAM-4F7K" 형태. 4글자만 입력해도 접두사를 붙여준다.
    var normalizedCode: String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !trimmed.contains("-"), trimmed.count == 4 { return "JAM-\(trimmed)" }
        return trimmed
    }

    var isCodeComplete: Bool { normalizedCode.count == 8 }

    var foundRoom: TripRoom? {
        if case .found(let room) = lookupState { return room }
        return nil
    }

    var canJoin: Bool { foundRoom != nil && !isJoining }

    var fieldError: String? {
        if case .failed(let message) = lookupState { return message }
        return nil
    }

    /// 코드가 완성되면 방 정보를 확인한다. (입력이 바뀌면 이전 결과는 버린다)
    func lookup() async {
        joinErrorMessage = nil
        guard isCodeComplete else {
            lookupState = .idle
            return
        }
        let requested = normalizedCode
        lookupState = .checking
        do {
            let room = try await roomRepository.lookupRoom(inviteCode: requested)
            guard requested == normalizedCode else { return }
            lookupState = .found(room)
        } catch {
            guard requested == normalizedCode else { return }
            lookupState = .failed(AppError(error).errorDescription ?? "초대 코드를 확인해 주세요.")
        }
    }

    /// 참여한 방의 id. 실패하면 nil.
    func join() async -> Int? {
        guard canJoin else { return nil }
        isJoining = true
        joinErrorMessage = nil
        defer { isJoining = false }
        do {
            return try await roomRepository.joinRoom(inviteCode: normalizedCode)
        } catch {
            joinErrorMessage = AppError(error).errorDescription
            return nil
        }
    }

    func previewMeta(for room: TripRoom) -> String {
        let names = room.members.map(\.nickname).joined(separator: ", ")
        let range = JammyDate.range(room.startDate, room.endDate)
        return names.isEmpty ? range : "\(range) · \(names)"
    }

    func memberCountText(for room: TripRoom) -> String {
        if let limit = room.memberLimit { return "\(room.memberCount) / \(limit)명 참여 중" }
        return "\(room.memberCount)명 참여 중"
    }

    private func formatCode() {
        let upper = code.uppercased()
        if upper != code { code = upper }
    }
}
