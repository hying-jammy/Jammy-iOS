import SwiftUI
import Observation

enum AuthRoute: Hashable {
    case login
    case signUp
}

enum MainRoute: Hashable {
    case createRoom
    case joinRoom
    case inviteCode(roomID: UUID)
    case room(roomID: UUID)
    case capsule(roomID: UUID)
}

/// 앱 전체 라우팅. 인증 상태에 따라 루트(온보딩 ↔ 메인)를 전환하고,
/// 각 루트의 `NavigationStack` 경로를 보관한다.
@MainActor
@Observable
final class AppRouter {
    enum Root { case onboarding, main }

    var root: Root = .onboarding
    var authPath: [AuthRoute] = []
    var mainPath: [MainRoute] = []

    func didSignIn() {
        authPath = []
        mainPath = []
        root = .main
    }

    func didSignOut() {
        mainPath = []
        authPath = []
        root = .onboarding
    }

    func push(_ route: MainRoute) {
        mainPath.append(route)
    }

    /// 현재 화면을 다른 화면으로 교체한다. (예: 방 만들기 → 초대 코드)
    func replaceTop(with route: MainRoute) {
        if !mainPath.isEmpty { mainPath.removeLast() }
        mainPath.append(route)
    }

    /// 스택을 비우고 해당 방으로 들어간다.
    func enterRoom(_ roomID: UUID) {
        mainPath = [.room(roomID: roomID)]
    }
}
