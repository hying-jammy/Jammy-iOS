import SwiftUI

struct LoginView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                JammyTopBar(onBack: { dismiss() })
                ScreenIntro(title: "다시 만나 반가워요!", subtitle: "계정으로 로그인하고 친구들의 여행을 이어가세요.")

                JammyTextField(
                    title: "이메일",
                    placeholder: "example@jammy.com",
                    text: $viewModel.email,
                    systemImage: "envelope",
                    keyboard: .emailAddress,
                    textContentType: .emailAddress
                )
                JammyTextField(
                    title: "비밀번호",
                    placeholder: "비밀번호를 입력해 주세요",
                    text: $viewModel.password,
                    systemImage: "lock",
                    isSecure: true,
                    errorMessage: viewModel.errorMessage,
                    textContentType: .password
                )

                JammyButton(title: viewModel.isSubmitting ? "로그인 중…" : "로그인") {
                    Task {
                        if await viewModel.submit() { router.didSignIn() }
                    }
                }
                .disabled(!viewModel.canSubmit)
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 6) {
                Text("처음이신가요?")
                    .foregroundStyle(Color(.jammyTextSecondary))
                Button("회원가입") { router.authPath = [.signUp] }
                    .foregroundStyle(Color(.jammyPrimary))
                    .fontWeight(.bold)
            }
            .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.jammyBackground))
        }
        .jammyScreenStyle()
    }
}

#Preview {
    NavigationStack {
        LoginView(viewModel: AppContainer.mock().makeLoginViewModel())
    }
    .environment(AppRouter())
}
