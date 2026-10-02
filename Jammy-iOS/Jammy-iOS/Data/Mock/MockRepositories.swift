import Foundation

// Mock 구현체. 실제 네트워크처럼 보이도록 약간의 지연을 둔다.
// API 가 준비되면 같은 프로토콜을 구현한 Remote*Repository 로 AppContainer 에서 교체한다.

private func simulateLatency() async {
    try? await Task.sleep(for: .milliseconds(350))
}

struct MockAuthRepository: AuthRepository {
    let store: MockStore

    func currentUser() async -> User? { store.currentUser }

    func login(email: String, password: String) async throws -> User {
        await simulateLatency()
        return try store.login(email: email, password: password)
    }

    func signUp(nickname: String, email: String, password: String) async throws -> User {
        await simulateLatency()
        return try store.signUp(nickname: nickname, email: email, password: password)
    }

    func logout() async { store.logout() }
}

struct MockRoomRepository: RoomRepository {
    let store: MockStore

    func fetchMyRooms() async throws -> [TripRoom] {
        await simulateLatency()
        return try store.myRooms()
    }

    func fetchRoom(id: UUID) async throws -> TripRoom {
        await simulateLatency()
        return try store.room(id: id)
    }

    func lookupRoom(inviteCode: String) async throws -> TripRoom {
        await simulateLatency()
        return try store.lookupRoom(inviteCode: inviteCode)
    }

    func createRoom(_ draft: NewRoomDraft) async throws -> TripRoom {
        await simulateLatency()
        return try store.createRoom(draft)
    }

    func joinRoom(inviteCode: String) async throws -> TripRoom {
        await simulateLatency()
        return try store.joinRoom(inviteCode: inviteCode)
    }
}

struct MockDiaryRepository: DiaryRepository {
    let store: MockStore

    func fetchFeed(roomID: UUID) async throws -> [DiaryEntry] {
        await simulateLatency()
        return try store.feed(roomID: roomID)
    }

    func fetchTimeline(roomID: UUID) async throws -> [DiaryEntry] {
        await simulateLatency()
        return try store.timeline(roomID: roomID)
    }

    func addEntry(_ draft: NewDiaryDraft) async throws -> DiaryEntry {
        await simulateLatency()
        return try store.addEntry(draft)
    }
}

struct MockCapsuleRepository: CapsuleRepository {
    let store: MockStore

    func fetchCapsuleDetail(roomID: UUID) async throws -> CapsuleDetail {
        await simulateLatency()
        return try store.capsuleDetail(roomID: roomID)
    }
}
