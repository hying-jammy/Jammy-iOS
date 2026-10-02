import Foundation
import Observation

/// 의존성 조립 지점. Mock ↔ Remote 전환은 여기서만 바뀐다.
/// API 가 준비되면 `live()` 를 추가해 Remote*Repository 를 주입한다.
@MainActor
@Observable
final class AppContainer {
    let dateProvider: DateProvider
    let authRepository: AuthRepository
    let roomRepository: RoomRepository
    let diaryRepository: DiaryRepository
    let capsuleRepository: CapsuleRepository

    init(
        dateProvider: DateProvider,
        authRepository: AuthRepository,
        roomRepository: RoomRepository,
        diaryRepository: DiaryRepository,
        capsuleRepository: CapsuleRepository
    ) {
        self.dateProvider = dateProvider
        self.authRepository = authRepository
        self.roomRepository = roomRepository
        self.diaryRepository = diaryRepository
        self.capsuleRepository = capsuleRepository
    }

    static func mock(dateProvider: DateProvider = SystemDateProvider()) -> AppContainer {
        let store = MockStore(dateProvider: dateProvider)
        return AppContainer(
            dateProvider: dateProvider,
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

    func makeInviteCodeViewModel(roomID: UUID) -> InviteCodeViewModel {
        InviteCodeViewModel(roomID: roomID, roomRepository: roomRepository)
    }

    func makeJoinRoomViewModel() -> JoinRoomViewModel {
        JoinRoomViewModel(roomRepository: roomRepository)
    }

    func makeRoomMainViewModel(roomID: UUID) -> RoomMainViewModel {
        RoomMainViewModel(roomID: roomID, roomRepository: roomRepository, diaryRepository: diaryRepository, dateProvider: dateProvider)
    }

    func makeWriteDiaryViewModel(roomID: UUID) -> WriteDiaryViewModel {
        WriteDiaryViewModel(roomID: roomID, roomRepository: roomRepository, diaryRepository: diaryRepository, dateProvider: dateProvider)
    }

    func makeCapsuleDetailViewModel(roomID: UUID) -> CapsuleDetailViewModel {
        CapsuleDetailViewModel(roomID: roomID, capsuleRepository: capsuleRepository, dateProvider: dateProvider)
    }
}
