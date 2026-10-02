import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class WriteDiaryViewModel {
    static let maxTextLength = 500
    static let maxPhotos = 5

    var text = "" {
        didSet {
            if text.count > Self.maxTextLength { text = String(text.prefix(Self.maxTextLength)) }
        }
    }
    var visibility: DiaryVisibility = .friends
    private(set) var photoData: [Data] = []
    private(set) var isCapsuleAvailable = true
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    let roomID: UUID
    private let roomRepository: RoomRepository
    private let diaryRepository: DiaryRepository
    private let dateProvider: DateProvider

    init(roomID: UUID, roomRepository: RoomRepository, diaryRepository: DiaryRepository, dateProvider: DateProvider) {
        self.roomID = roomID
        self.roomRepository = roomRepository
        self.diaryRepository = diaryRepository
        self.dateProvider = dateProvider
    }

    var countText: String { "\(text.count) / \(Self.maxTextLength)" }

    var canSubmit: Bool {
        let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !photoData.isEmpty
        return hasContent && !isSubmitting
    }

    /// 타임캡슐이 이미 열렸다면 비밀 일기는 더 이상 쓸 수 없다.
    func load() async {
        guard let room = try? await roomRepository.fetchRoom(id: roomID) else { return }
        let isOpened = room.capsule?.status(at: dateProvider.now) == .opened
        isCapsuleAvailable = room.capsule != nil && !isOpened
        if !isCapsuleAvailable { visibility = .friends }
    }

    func loadPhotos(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items.prefix(Self.maxPhotos) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        photoData = loaded
    }

    func removePhoto(at index: Int) {
        guard photoData.indices.contains(index) else { return }
        photoData.remove(at: index)
    }

    /// 저장에 성공하면 true.
    func save() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await diaryRepository.addEntry(
                NewDiaryDraft(
                    roomID: roomID,
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    photoData: photoData,
                    visibility: visibility
                )
            )
            return true
        } catch {
            errorMessage = AppError(error).errorDescription
            return false
        }
    }
}
