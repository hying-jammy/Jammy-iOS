import SwiftUI

struct SignUpView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SignUpViewModel

    init(viewModel: SignUpViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                JammyTopBar(onBack: { dismiss() })
                ScreenIntro(title: "Jammy에 오신 걸 환영해요", subtitle: "친구들과 여행의 순간을 담을 준비를 해볼까요?")

                JammyTextField(
                    title: "닉네임",
                    placeholder: "친구들에게 보일 이름",
                    text: $viewModel.nickname,
                    systemImage: "person",
                    textContentType: .nickname,
                    autocapitalization: .never
                )
                JammyTextField(
                    title: "이메일",
                    placeholder: "example@jammy.com",
                    text: $viewModel.email,
                    systemImage: "envelope",
                    errorMessage: viewModel.emailError,
                    keyboard: .emailAddress,
                    textContentType: .emailAddress
                )
                JammyTextField(
                    title: "비밀번호",
                    placeholder: "8자 이상 입력해 주세요",
                    text: $viewModel.password,
                    systemImage: "lock",
                    isSecure: true,
                    hint: "영문과 숫자를 함께 사용해 주세요.",
                    errorMessage: viewModel.passwordError,
                    textContentType: .newPassword
                )

                JammyCheckboxRow(isOn: $viewModel.agreedToTerms, text: "이용약관 및 개인정보 처리방침에 동의해요 (필수)")

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
            VStack(spacing: 14) {
                JammyButton(title: viewModel.isSubmitting ? "가입 중…" : "가입하기") {
                    Task {
                        if await viewModel.submit() { router.didSignIn() }
                    }
                }
                .disabled(!viewModel.canSubmit)

                HStack(spacing: 6) {
                    Text("이미 계정이 있나요?")
                        .foregroundStyle(Color(.jammyTextSecondary))
                    Button("로그인") { router.authPath = [.login] }
                        .foregroundStyle(Color(.jammyPrimary))
                        .fontWeight(.bold)
                }
                .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.jammyBackground))
        }
        .jammyScreenStyle()
    }
}

#Preview {
    NavigationStack {
        SignUpView(viewModel: AppContainer.mock().makeSignUpViewModel())
    }
    .environment(AppRouter())
}
