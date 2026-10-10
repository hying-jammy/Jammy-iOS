import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class WriteDiaryViewModel {
    /// 서버 명세: 글은 최대 500자, 사진은 최대 1장.
    static let maxTextLength = 500

    var text = "" {
        didSet {
            if text.count > Self.maxTextLength { text = String(text.prefix(Self.maxTextLength)) }
        }
    }
    var visibility: DiaryVisibility = .friends
    private(set) var photoData: Data?
    private(set) var isCapsuleAvailable = true
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    let roomID: Int
    private let roomRepository: RoomRepository
    private let diaryRepository: DiaryRepository
    private let dateProvider: DateProvider

    init(roomID: Int, roomRepository: RoomRepository, diaryRepository: DiaryRepository, dateProvider: DateProvider) {
        self.roomID = roomID
        self.roomRepository = roomRepository
        self.diaryRepository = diaryRepository
        self.dateProvider = dateProvider
    }

    var countText: String { "\(text.count) / \(Self.maxTextLength)" }

    var canSubmit: Bool {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasText && !isSubmitting
    }

    /// 타임캡슐이 이미 열렸다면 비밀 일기는 더 이상 쓸 수 없다.
    func load() async {
        guard let room = try? await roomRepository.fetchRoom(id: roomID) else { return }
        let isOpened = room.capsule?.status(at: dateProvider.now) == .opened
        isCapsuleAvailable = room.capsule != nil && !isOpened
        if !isCapsuleAvailable { visibility = .friends }
    }

    func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else {
            photoData = nil
            return
        }
        photoData = try? await item.loadTransferable(type: Data.self)
    }

    func removePhoto() {
        photoData = nil
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
