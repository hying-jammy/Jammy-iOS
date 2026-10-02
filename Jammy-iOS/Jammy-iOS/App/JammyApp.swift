import SwiftUI

@main
struct JammyApp: App {
    @State private var container = AppContainer.mock()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(router)
                .preferredColorScheme(.light)
        }
    }
}
