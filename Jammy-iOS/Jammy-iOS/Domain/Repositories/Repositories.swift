import Foundation

// 화면(ViewModel)은 아래 프로토콜에만 의존한다.
// Mock(Data/Mock)과 Remote(Data/Remote) 구현을 AppContainer 에서 교체한다.
// 서버 명세: Notion "Jammy - 문서 / API 명세서"

protocol AuthRepository {
    /// 저장된 세션의 사용자. (서버가 토큰을 발급하지 않아 userId 를 로컬에 저장한다)
    func currentUser() async -> User?
    func login(email: String, password: String) async throws -> User
    /// 가입 성공 시 값을 돌려주지 않는다. (서버 응답이 "OK" 뿐) 자동 로그인은 호출하는 쪽에서 한다.
    func signUp(nickname: String, email: String, password: String) async throws
    func logout() async
}

protocol RoomRepository {
    func fetchMyRooms() async throws -> [TripRoom]
    func fetchRoom(id: Int) async throws -> TripRoom
    /// 초대 코드로 방 정보를 미리 확인한다. (참여 전 미리보기)
    func lookupRoom(inviteCode: String) async throws -> TripRoom
    func createRoom(_ draft: NewRoomDraft) async throws -> TripRoom
    /// 참여한 방의 id
    func joinRoom(inviteCode: String) async throws -> Int
}

protocol DiaryRepository {
    /// 방의 일기 목록, 최신순. 서버가 타임캡슐 일기(`.capsule`)도 섞어 내려주므로,
    /// 화면에서는 `.capsule` 항목의 내용을 가려서 보여줘야 한다.
    func fetchFeed(roomID: Int) async throws -> [DiaryEntry]
    /// 타임캡슐 일기, 오래된 순. 공개 시간 전이면 `AppError.capsuleNotOpened`.
    func fetchCapsuleDiaries(roomID: Int) async throws -> [DiaryEntry]
    /// 작성된 일기의 id
    func addEntry(_ draft: NewDiaryDraft) async throws -> Int
}

protocol CapsuleRepository {
    func fetchCapsule(roomID: Int) async throws -> CapsuleInfo
}

/// 로그인 세션 저장소. 서버가 토큰을 주지 않으므로 userId/닉네임만 보관한다.
protocol SessionStore: AnyObject {
    var user: User? { get set }
}
