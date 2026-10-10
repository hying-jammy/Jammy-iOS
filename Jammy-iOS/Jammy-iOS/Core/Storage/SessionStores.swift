import Foundation

/// 앱을 다시 켜도 로그인 상태가 유지되도록 userId/닉네임을 UserDefaults 에 저장한다.
/// 서버가 토큰을 발급하지 않아 비밀 값이 아니다. (토큰 방식으로 바뀌면 Keychain 으로 옮긴다)
final class UserDefaultsSessionStore: SessionStore {
    private let defaults: UserDefaults
    private let userIDKey = "jammy.session.userId"
    private let nicknameKey = "jammy.session.nickname"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var user: User? {
        get {
            guard defaults.object(forKey: userIDKey) != nil,
                  let nickname = defaults.string(forKey: nicknameKey)
            else { return nil }
            return User(id: defaults.integer(forKey: userIDKey), nickname: nickname)
        }
        set {
            if let newValue {
                defaults.set(newValue.id, forKey: userIDKey)
                defaults.set(newValue.nickname, forKey: nicknameKey)
            } else {
                defaults.removeObject(forKey: userIDKey)
                defaults.removeObject(forKey: nicknameKey)
            }
        }
    }
}

/// 메모리에만 두는 세션. Mock 과 테스트에서 쓴다.
final class InMemorySessionStore: SessionStore {
    var user: User?

    init(user: User? = nil) {
        self.user = user
    }
}
