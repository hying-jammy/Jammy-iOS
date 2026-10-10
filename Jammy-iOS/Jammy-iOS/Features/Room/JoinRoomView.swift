import SwiftUI

/// 초대 코드 입력 → 방 미리보기 → 참여.
struct JoinRoomView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: JoinRoomViewModel

    init(viewModel: JoinRoomViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                JammyTopBar(title: "초대 코드 입력", onBack: { dismiss() })
                ScreenIntro(title: "초대 코드가 있나요?", subtitle: "친구에게 받은 코드를 입력하면 바로 방에 참여할 수 있어요.")

                VStack(alignment: .leading, spacing: 10) {
                    JammyTextField(
                        title: "초대 코드",
                        placeholder: "JAM-0000",
                        text: $viewModel.code,
                        systemImage: "key",
                        errorMessage: viewModel.fieldError,
                        autocapitalization: .characters
                    )
                    statusLine
                }

                if let room = viewModel.foundRoom {
                    preview(room)
                }

                if let message = viewModel.joinErrorMessage {
                    Text(message)
                        .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyError))
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.code) {
            Task { await viewModel.lookup() }
        }
        .safeAreaInset(edge: .bottom) {
            JammyButton(title: viewModel.isJoining ? "참여 중…" : "참여하기") {
                Task {
                    if let roomID = await viewModel.join() {
                        router.replaceTop(with: .room(roomID: roomID))
                    }
                }
            }
            .disabled(!viewModel.canJoin)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.jammyBackground))
        }
        .jammyScreenStyle()
    }

    @ViewBuilder
    private var statusLine: some View {
        switch viewModel.lookupState {
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("확인하고 있어요")
                    .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(.jammyTextSecondary))
            }
        case .found:
            Label("참여할 수 있는 방이에요", systemImage: "checkmark")
                .font(.pretendard(.semibold, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color(red: 0x5F / 255, green: 0x81 / 255, blue: 0x51 / 255))
        case .idle, .failed:
            EmptyView()
        }
    }

    private func preview(_ room: TripRoom) -> some View {
        HStack(spacing: 14) {
            PhotoPlaceholder(tone: .sunny)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(room.title)
                    .font(.pretendard(.bold, size: 18, relativeTo: .headline))
                    .foregroundStyle(Color(.jammyTextPrimary))
                Text(viewModel.previewMeta(for: room))
                    .font(.pretendard(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(.jammyTextSecondary))
                Label(viewModel.memberCountText(for: room), systemImage: "person.2")
                    .font(.pretendard(.medium, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color(.jammyTextSecondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(.jammySurfaceWarm), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.jammyBorder), lineWidth: 1)
        }
        .shadow(color: Color(.jammyPrimary).opacity(0.12), radius: 10, y: 8)
    }
}

#Preview {
    NavigationStack {
        JoinRoomView(viewModel: AppContainer.mock().makeJoinRoomViewModel())
    }
    .environment(AppRouter())
}
