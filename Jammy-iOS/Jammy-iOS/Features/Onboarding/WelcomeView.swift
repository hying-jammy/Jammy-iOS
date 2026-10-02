import SwiftUI

/// 초기 화면. 시작하기 → 회원가입, 이미 계정이 있어요 → 로그인.
struct WelcomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            Color(.jammyBackground).ignoresSafeArea()
            decoration

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 14) {
                    JamJarView(width: 174)
                    Text("Jammy")
                        .font(.pretendard(.extrabold, size: 44, relativeTo: .largeTitle))
                        .foregroundStyle(Color(.jammyPrimary))
                    Text("여행 중엔 함께 기록하고,\n여행 후엔 함께 열어봐요.")
                        .font(.pretendard(.medium, size: 16, relativeTo: .body))
                        .foregroundStyle(Color(.jammyTextSecondary))
                        .multilineTextAlignment(.center)
                }
                Spacer()
                VStack(spacing: 12) {
                    JammyButton(title: "시작하기") { router.authPath.append(.signUp) }
                    JammyButton(title: "이미 계정이 있어요", kind: .soft) { router.authPath.append(.login) }
                }
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// 배경 장식 원
    private var decoration: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(Color(.jammySecondarySoft))
                    .frame(width: 260, height: 260)
                    .position(x: proxy.size.width - 30, y: 40)
                Circle()
                    .fill(Color(.jammyPrimarySoft))
                    .frame(width: 200, height: 200)
                    .position(x: 20, y: proxy.size.height * 0.52)
                Circle()
                    .fill(Color(.jammyAccentGreen).opacity(0.18))
                    .frame(width: 120, height: 120)
                    .position(x: proxy.size.width - 10, y: proxy.size.height * 0.62)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
    .environment(AppRouter())
}
