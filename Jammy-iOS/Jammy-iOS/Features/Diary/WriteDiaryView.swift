import SwiftUI
import PhotosUI

/// 일기 작성: 사진, 글, 공개 범위(친구 공개 / 타임캡슐 보관).
struct WriteDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WriteDiaryViewModel
    @State private var pickerItems: [PhotosPickerItem] = []
    @FocusState private var isTextFocused: Bool
    let onSaved: () -> Void

    init(viewModel: WriteDiaryViewModel, onSaved: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                JammyTopBar(title: "오늘의 순간 담기", backImage: "xmark", backLabel: "닫기", onBack: { dismiss() })
                photoSection
                textSection
                visibilitySection
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyError))
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            JammyButton(title: viewModel.isSubmitting ? "저장 중…" : "저장하기") {
                Task {
                    if await viewModel.save() {
                        onSaved()
                        dismiss()
                    }
                }
            }
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.jammyBackground))
        }
        .task { await viewModel.load() }
        .onChange(of: pickerItems) {
            Task { await viewModel.loadPhotos(from: pickerItems) }
        }
        .background(Color(.jammyBackground).ignoresSafeArea())
    }

    // MARK: - Sections

    private var photoSection: some View {
        let maxPhotos = WriteDiaryViewModel.maxPhotos
        let hasPhotos = !viewModel.photoData.isEmpty
        return VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $pickerItems, maxSelectionCount: maxPhotos, matching: .images) {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(.jammyYellowText))
                        .frame(width: 48, height: 48)
                        .background(Color(.jammySecondarySoft), in: Circle())
                    Text(hasPhotos ? "사진 다시 고르기" : "사진 추가하기")
                        .font(.pretendard(.semibold, size: 15, relativeTo: .body))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text("여행의 한 장면을 올려보세요 (최대 \(maxPhotos)장)")
                        .font(.pretendard(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(.jammyTextTertiary))
                }
                .frame(maxWidth: .infinity)
                .frame(height: hasPhotos ? 130 : 170)
                .background(Color(.jammySurfaceWarm), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(.jammyPrimary), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                }
            }

            if !viewModel.photoData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.photoData.enumerated()), id: \.offset) { index, data in
                            JammyPhoto(data: data)
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        viewModel.removePhoto(at: index)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 22, height: 22)
                                            .background(Color(.jammyTextPrimary).opacity(0.7), in: Circle())
                                            .padding(4)
                                    }
                                    .accessibilityLabel("사진 삭제")
                                }
                        }
                    }
                }
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 기록")
                .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color(.jammyTextPrimary))

            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.text)
                        .font(.pretendard(.regular, size: 16))
                        .foregroundStyle(Color(.jammyTextPrimary))
                        .scrollContentBackground(.hidden)
                        .focused($isTextFocused)
                        .frame(height: 110)
                    if viewModel.text.isEmpty {
                        Text("오늘은 어떤 순간이 있었나요?")
                            .font(.pretendard(.regular, size: 16))
                            .foregroundStyle(Color(.jammyTextTertiary))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                Text(viewModel.countText)
                    .font(.pretendard(.medium, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color(.jammyTextTertiary))
            }
            .padding(12)
            .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(isTextFocused ? .jammyPrimary : .jammyBorder), lineWidth: isTextFocused ? 2 : 1)
            }
        }
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("공개 범위")
                .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color(.jammyTextPrimary))
            HStack(spacing: 12) {
                option(.friends, systemImage: "person.2", title: "친구들에게 공개", description: "작성 즉시 피드에 보여요", isEnabled: true)
                option(.capsule, systemImage: "lock", title: "타임캡슐에 보관", description: viewModel.isCapsuleAvailable ? "공개일까지 나만 볼 수 있어요" : "이미 열린 타임캡슐이에요", isEnabled: viewModel.isCapsuleAvailable)
            }
        }
    }

    private func option(_ value: DiaryVisibility, systemImage: String, title: String, description: String, isEnabled: Bool) -> some View {
        let isSelected = viewModel.visibility == value
        return Button {
            viewModel.visibility = value
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(isSelected ? .jammyPrimary : .jammyTextSecondary))
                    .frame(width: 36, height: 36)
                    .background(Color(isSelected ? .jammySurface : .jammyNeutralChip), in: Circle())
                Text(title)
                    .font(.pretendard(.bold, size: 15, relativeTo: .headline))
                    .foregroundStyle(Color(.jammyTextPrimary))
                Text(description)
                    .font(.pretendard(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color(.jammyTextSecondary))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(isSelected ? .jammyPrimarySoft : .jammySurface), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(isSelected ? .jammyPrimary : .jammyBorder), lineWidth: isSelected ? 2 : 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    WriteDiaryView(viewModel: AppContainer.mock().makeWriteDiaryViewModel(roomID: UUID()))
}
