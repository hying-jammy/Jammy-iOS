import SwiftUI

/// 여행 방 만들기: 제목, 기간, 인원, 타임캡슐 공개 날짜·시간.
struct CreateRoomView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateRoomViewModel

    init(viewModel: CreateRoomViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                JammyTopBar(title: "여행 방 만들기", onBack: { dismiss() })
                ScreenIntro(title: "어디로 떠나나요?", subtitle: "함께 떠날 친구들과 우리만의 방을 만들어요.")

                JammyTextField(title: "여행 제목", placeholder: "예: 부산 여행", text: $viewModel.title, autocapitalization: .sentences)

                HStack(spacing: 12) {
                    JammyDateField(title: "시작일", selection: $viewModel.startDate)
                    JammyDateField(title: "종료일", selection: $viewModel.endDate, range: viewModel.startDate...)
                }

                memberStepper

                VStack(alignment: .leading, spacing: 10) {
                    Label("타임캡슐 공개 시간", systemImage: "lock")
                        .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text("여행 마지막 날, 모두의 비밀 기록이 열리는 시간이에요.")
                        .font(.pretendard(.regular, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyTextSecondary))
                    HStack(spacing: 12) {
                        JammyDateField(title: "공개 날짜", selection: $viewModel.capsuleDate, range: viewModel.endDate...)
                        JammyDateField(title: "공개 시간", selection: $viewModel.capsuleTime, systemImage: "clock", components: .hourAndMinute)
                    }
                }

                if let message = viewModel.validationMessage ?? viewModel.errorMessage {
                    Text(message)
                        .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyError))
                } else {
                    NoticeBanner(text: "방을 만들면 초대 코드가 발급되고, 타임캡슐은 공개 시간까지 잠겨요.")
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            JammyButton(title: viewModel.isSubmitting ? "만드는 중…" : "방 만들기") {
                Task {
                    if let roomID = await viewModel.create() {
                        router.replaceTop(with: .inviteCode(roomID: roomID))
                    }
                }
            }
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.jammyBackground))
        }
        .jammyScreenStyle()
    }

    private var memberStepper: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("참여 인원")
                .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color(.jammyTextPrimary))
            HStack {
                stepperButton(systemImage: "minus", tone: Color(.jammyNeutralChip), tint: Color(.jammyTextSecondary), label: "인원 줄이기", isEnabled: viewModel.canDecrease) {
                    viewModel.decreaseMembers()
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .foregroundStyle(Color(.jammyPrimary))
                    Text("\(viewModel.maxMembers)명")
                        .font(.pretendard(.bold, size: 17, relativeTo: .headline))
                        .foregroundStyle(Color(.jammyTextPrimary))
                }
                Spacer()
                stepperButton(systemImage: "plus", tone: Color(.jammyPrimarySoft), tint: Color(.jammyPrimary), label: "인원 늘리기", isEnabled: viewModel.canIncrease) {
                    viewModel.increaseMembers()
                }
            }
            .padding(8)
            .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(.jammyBorder), lineWidth: 1)
            }
        }
    }

    private func stepperButton(
        systemImage: String,
        tone: Color,
        tint: Color,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tone, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

#Preview {
    NavigationStack {
        CreateRoomView(viewModel: AppContainer.mock().makeCreateRoomViewModel())
    }
    .environment(AppRouter())
}
