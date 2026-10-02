import Foundation
import Observation

@MainActor
@Observable
final class CreateRoomViewModel {
    static let memberRange = 2...10

    var title = ""
    var startDate: Date
    var endDate: Date {
        didSet {
            // 타임캡슐 공개일은 여행 마지막 날보다 앞설 수 없다.
            if capsuleDate < endDate { capsuleDate = endDate }
        }
    }
    var maxMembers = 3
    /// 타임캡슐 공개 날짜 / 시간 (기본: 여행 마지막 날 오후 8시)
    var capsuleDate: Date
    var capsuleTime: Date

    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let roomRepository: RoomRepository
    private let dateProvider: DateProvider
    private let calendar = Calendar.current

    init(roomRepository: RoomRepository, dateProvider: DateProvider) {
        self.roomRepository = roomRepository
        self.dateProvider = dateProvider

        let now = dateProvider.now
        let end = Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now
        startDate = now
        endDate = end
        capsuleDate = end
        capsuleTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
    }

    /// 공개 날짜 + 공개 시간을 합친 값
    var capsuleOpenAt: Date {
        let time = calendar.dateComponents([.hour, .minute], from: capsuleTime)
        return calendar.date(bySettingHour: time.hour ?? 20, minute: time.minute ?? 0, second: 0, of: capsuleDate) ?? capsuleDate
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var validationMessage: String? {
        if trimmedTitle.isEmpty { return nil }
        if calendar.startOfDay(for: endDate) < calendar.startOfDay(for: startDate) {
            return "종료일은 시작일 이후여야 해요."
        }
        if capsuleOpenAt <= dateProvider.now {
            return "타임캡슐 공개 시간은 지금보다 뒤여야 해요."
        }
        return nil
    }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty && validationMessage == nil && !isSubmitting
    }

    func increaseMembers() { maxMembers = min(maxMembers + 1, Self.memberRange.upperBound) }
    func decreaseMembers() { maxMembers = max(maxMembers - 1, Self.memberRange.lowerBound) }
    var canIncrease: Bool { maxMembers < Self.memberRange.upperBound }
    var canDecrease: Bool { maxMembers > Self.memberRange.lowerBound }

    /// 만들어진 방의 id. 실패하면 nil.
    func create() async -> UUID? {
        guard canSubmit else { return nil }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let room = try await roomRepository.createRoom(
                NewRoomDraft(
                    title: trimmedTitle,
                    startDate: startDate,
                    endDate: endDate,
                    maxMembers: maxMembers,
                    capsuleOpenAt: capsuleOpenAt
                )
            )
            return room.id
        } catch {
            errorMessage = AppError(error).errorDescription
            return nil
        }
    }
}
