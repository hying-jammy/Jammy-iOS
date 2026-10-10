import Foundation
import Observation

/// 의존성 조립 지점. Mock ↔ Remote 전환은 여기서만 바뀐다.
/// `make()` 는 서버 주소(`APIConfig.baseURL`)가 설정되어 있으면 Remote 를, 비어 있으면 Mock 을 쓴다.
@MainActor
@Observable
final class AppContainer {
    let isMock: Bool
    let dateProvider: DateProvider
    let sessionStore: SessionStore
    let authRepository: AuthRepository
    let roomRepository: RoomRepository
    let diaryRepository: DiaryRepository
    let capsuleRepository: CapsuleRepository

    init(
        isMock: Bool,
        dateProvider: DateProvider,
        sessionStore: SessionStore,
        authRepository: AuthRepository,
        roomRepository: RoomRepository,
        diaryRepository: DiaryRepository,
        capsuleRepository: CapsuleRepository
    ) {
        self.isMock = isMock
        self.dateProvider = dateProvider
        self.sessionStore = sessionStore
        self.authRepository = authRepository
        self.roomRepository = roomRepository
        self.diaryRepository = diaryRepository
        self.capsuleRepository = capsuleRepository
    }

    /// 앱을 다시 켰을 때 이전 로그인 상태가 남아 있는지
    var hasStoredSession: Bool { sessionStore.user != nil }

    static func make() -> AppContainer {
        if let baseURL = APIConfig.baseURL {
            return live(baseURL: baseURL)
        }
        return mock()
    }

    static func live(
        baseURL: URL,
        sessionStore: SessionStore? = nil,
        dateProvider: DateProvider = SystemDateProvider()
    ) -> AppContainer {
        let sessionStore = sessionStore ?? UserDefaultsSessionStore()
        let client = APIClient(baseURL: baseURL)
        return AppContainer(
            isMock: false,
            dateProvider: dateProvider,
            sessionStore: sessionStore,
            authRepository: RemoteAuthRepository(client: client, session: sessionStore),
            roomRepository: RemoteRoomRepository(client: client, session: sessionStore),
            diaryRepository: RemoteDiaryRepository(client: client, session: sessionStore),
            capsuleRepository: RemoteCapsuleRepository(client: client)
        )
    }

    static func mock(dateProvider: DateProvider = SystemDateProvider()) -> AppContainer {
        let sessionStore = InMemorySessionStore()
        let store = MockStore(dateProvider: dateProvider, session: sessionStore)
        return AppContainer(
            isMock: true,
            dateProvider: dateProvider,
            sessionStore: sessionStore,
            authRepository: MockAuthRepository(store: store),
            roomRepository: MockRoomRepository(store: store),
            diaryRepository: MockDiaryRepository(store: store),
            capsuleRepository: MockCapsuleRepository(store: store)
        )
    }

    // MARK: - ViewModel 팩토리

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authRepository: authRepository)
    }

    func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(authRepository: authRepository)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(authRepository: authRepository, roomRepository: roomRepository, dateProvider: dateProvider)
    }

    func makeCreateRoomViewModel() -> CreateRoomViewModel {
        CreateRoomViewModel(roomRepository: roomRepository, dateProvider: dateProvider)
    }

    func makeInviteCodeViewModel(room: TripRoom) -> InviteCodeViewModel {
        InviteCodeViewModel(room: room)
    }

    func makeJoinRoomViewModel() -> JoinRoomViewModel {
        JoinRoomViewModel(roomRepository: roomRepository)
    }

    func makeRoomMainViewModel(roomID: Int) -> RoomMainViewModel {
        RoomMainViewModel(roomID: roomID, roomRepository: roomRepository, diaryRepository: diaryRepository, dateProvider: dateProvider)
    }

    func makeWriteDiaryViewModel(roomID: Int) -> WriteDiaryViewModel {
        WriteDiaryViewModel(roomID: roomID, roomRepository: roomRepository, diaryRepository: diaryRepository, dateProvider: dateProvider)
    }

    func makeCapsuleDetailViewModel(roomID: Int) -> CapsuleDetailViewModel {
        CapsuleDetailViewModel(roomID: roomID, capsuleRepository: capsuleRepository, diaryRepository: diaryRepository, dateProvider: dateProvider)
    }
}
