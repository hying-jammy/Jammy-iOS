import SwiftUI
import Observation

enum AuthRoute: Hashable {
    case login
    case signUp
}

enum MainRoute: Hashable {
    case createRoom
    case joinRoom
    /// 방 생성 응답에만 최대 인원이 있어서 방 정보를 그대로 넘긴다.
    case inviteCode(room: TripRoom)
    case room(roomID: Int)
    case capsule(roomID: Int)
}

/// 앱 전체 라우팅. 인증 상태에 따라 루트(온보딩 ↔ 메인)를 전환하고,
/// 각 루트의 `NavigationStack` 경로를 보관한다.
@MainActor
@Observable
final class AppRouter {
    enum Root { case onboarding, main }

    var root: Root
    var authPath: [AuthRoute] = []
    var mainPath: [MainRoute] = []

    init(root: Root = .onboarding) {
        self.root = root
    }

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
    func enterRoom(_ roomID: Int) {
        mainPath = [.room(roomID: roomID)]
    }
}
