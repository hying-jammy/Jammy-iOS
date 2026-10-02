import Foundation

// 화면(ViewModel)은 아래 프로토콜에만 의존한다.
// 지금은 Data/Mock 구현을 쓰고, API 가 준비되면 Data/Remote 구현으로 AppContainer 에서 교체한다.

protocol AuthRepository {
    func currentUser() async -> User?
    func login(email: String, password: String) async throws -> User
    func signUp(nickname: String, email: String, password: String) async throws -> User
    func logout() async
}

protocol RoomRepository {
    func fetchMyRooms() async throws -> [TripRoom]
    func fetchRoom(id: UUID) async throws -> TripRoom
    /// 초대 코드로 방 정보를 미리 확인한다. (참여 전 미리보기)
    func lookupRoom(inviteCode: String) async throws -> TripRoom
    func createRoom(_ draft: NewRoomDraft) async throws -> TripRoom
    func joinRoom(inviteCode: String) async throws -> TripRoom
}

protocol DiaryRepository {
    /// 공개 일기만, 최신순.
    func fetchFeed(roomID: UUID) async throws -> [DiaryEntry]
    /// 내가 볼 수 있는 모든 기록(공개 일기 + 내 비밀 일기 + 열린 타임캡슐 기록), 오래된 순.
    func fetchTimeline(roomID: UUID) async throws -> [DiaryEntry]
    func addEntry(_ draft: NewDiaryDraft) async throws -> DiaryEntry
}

protocol CapsuleRepository {
    func fetchCapsuleDetail(roomID: UUID) async throws -> CapsuleDetail
}
