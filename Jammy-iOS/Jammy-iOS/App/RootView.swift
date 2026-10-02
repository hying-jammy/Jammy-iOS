import SwiftUI

/// 인증 상태에 따라 온보딩 흐름과 메인 흐름을 전환한다.
struct RootView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        ZStack {
            switch router.root {
            case .onboarding:
                NavigationStack(path: $router.authPath) {
                    WelcomeView()
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .login:
                                LoginView(viewModel: container.makeLoginViewModel())
                            case .signUp:
                                SignUpView(viewModel: container.makeSignUpViewModel())
                            }
                        }
                }
                .transition(.opacity)
            case .main:
                NavigationStack(path: $router.mainPath) {
                    HomeView(viewModel: container.makeHomeViewModel())
                        .navigationDestination(for: MainRoute.self) { route in
                            mainDestination(route)
                        }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.root)
        .background(Color(.jammyBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func mainDestination(_ route: MainRoute) -> some View {
        switch route {
        case .createRoom:
            CreateRoomView(viewModel: container.makeCreateRoomViewModel())
        case .joinRoom:
            JoinRoomView(viewModel: container.makeJoinRoomViewModel())
        case .inviteCode(let roomID):
            InviteCodeView(viewModel: container.makeInviteCodeViewModel(roomID: roomID))
        case .room(let roomID):
            RoomMainView(viewModel: container.makeRoomMainViewModel(roomID: roomID))
        case .capsule(let roomID):
            CapsuleDetailView(viewModel: container.makeCapsuleDetailViewModel(roomID: roomID))
        }
    }
}
