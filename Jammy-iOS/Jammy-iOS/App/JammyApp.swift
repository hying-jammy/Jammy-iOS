import SwiftUI

@main
struct JammyApp: App {
    @State private var container: AppContainer
    @State private var router: AppRouter

    init() {
        let container = AppContainer.mock()
        _container = State(initialValue: container)
        // 이전에 로그인한 기록이 있으면 홈에서 바로 시작한다.
        _router = State(initialValue: AppRouter(root: container.hasStoredSession ? .main : .onboarding))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(router)
                .preferredColorScheme(.light)
        }
    }
}
