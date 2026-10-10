import Foundation

/// 서버 대신 메모리에 데이터를 들고 있는 Mock 저장소.
/// "방 만들기 → 홈 목록에 나타남" 같은 흐름이 앱 안에서 이어지도록 상태를 유지한다.
/// 실제 서버 명세(Notion API 명세서)와 같은 규칙을 따른다:
/// - 공개 일기는 방 참여자에게 즉시 보이고, 타임캡슐 일기는 공개 시각 이후에만 조회된다.
/// - 방 상세/목록에는 최대 인원이 없고, 초대 코드 확인·방 생성 응답에만 있다.
@MainActor
final class MockStore {
    private struct Account {
        var user: User
        var email: String
        var password: String
    }

    private struct StoredEntry {
        var roomID: Int
        var entry: DiaryEntry
    }

    private let dateProvider: DateProvider
    private let session: SessionStore
    private var accounts: [Account] = []
    private var rooms: [TripRoom] = []
    private var entries: [StoredEntry] = []
    private var nextID = 1000

    private let seedUser = User(id: 1, nickname: "나연")

    init(dateProvider: DateProvider = SystemDateProvider(), session: SessionStore? = nil) {
        self.dateProvider = dateProvider
        self.session = session ?? InMemorySessionStore()
        accounts = [
            Account(user: seedUser, email: "nayeon@jammy.com", password: "jammy1234"),
            Account(user: User(id: 2, nickname: "민지"), email: "minji@jammy.com", password: "jammy1234"),
            Account(user: User(id: 3, nickname: "서준"), email: "seojun@jammy.com", password: "jammy1234")
        ]
        seed()
    }

    private var now: Date { dateProvider.now }

    // MARK: - Auth

    func login(email: String, password: String) throws -> User {
        let normalized = email.lowercased()
        // 데모용 실패 케이스
        if normalized == "fail@jammy.com" { throw AppError.invalidCredentials }
        if let account = accounts.first(where: { $0.email == normalized }) {
            guard account.password == password else { throw AppError.invalidCredentials }
            session.user = account.user
            return account.user
        }
        // 가입하지 않은 이메일은 데모 계정으로 로그인한다.
        session.user = seedUser
        return seedUser
    }

    func signUp(nickname: String, email: String, password: String) throws {
        let normalized = email.lowercased()
        // 데모용 실패 케이스
        if normalized == "taken@jammy.com" || accounts.contains(where: { $0.email == normalized }) {
            throw AppError.emailAlreadyUsed
        }
        accounts.append(Account(user: User(id: makeID(), nickname: nickname), email: normalized, password: password))
    }

    func currentUser() -> User? { session.user }

    func logout() { session.user = nil }

    // MARK: - Room

    func myRooms() throws -> [TripRoom] {
        let me = try requireMe()
        return rooms
            .filter { room in room.members.contains { $0.nickname == me.nickname } }
            .sorted { $0.startDate > $1.startDate }
            // 목록 API 는 참여자 목록과 최대 인원을 주지 않는다.
            .map { room in
                var item = room
                item.members = []
                item.memberLimit = nil
                return item
            }
    }

    func room(id: Int) throws -> TripRoom {
        guard var room = rooms.first(where: { $0.id == id }) else { throw AppError.notFound }
        room.memberLimit = nil
        return room
    }

    func lookupRoom(inviteCode: String) throws -> TripRoom {
        let code = Self.normalize(inviteCode)
        guard var room = rooms.first(where: { $0.inviteCode == code }) else { throw AppError.invalidInviteCode }
        room.capsule = nil
        return room
    }

    func createRoom(_ draft: NewRoomDraft) throws -> TripRoom {
        let me = try requireMe()
        let room = TripRoom(
            id: makeID(),
            title: draft.title,
            startDate: draft.startDate,
            endDate: draft.endDate,
            inviteCode: makeInviteCode(),
            members: [Member(nickname: me.nickname)],
            memberCount: 1,
            memberLimit: draft.memberLimit,
            capsule: TimeCapsule(title: TimeCapsule.defaultTitle(forRoom: draft.title), openAt: draft.capsuleOpenAt)
        )
        rooms.append(room)
        return room
    }

    func joinRoom(inviteCode: String) throws -> Int {
        let me = try requireMe()
        let code = Self.normalize(inviteCode)
        guard let index = rooms.firstIndex(where: { $0.inviteCode == code }) else { throw AppError.invalidInviteCode }
        if rooms[index].members.contains(where: { $0.nickname == me.nickname }) { throw AppError.alreadyMember }
        if let limit = rooms[index].memberLimit, rooms[index].members.count >= limit { throw AppError.roomFull }
        rooms[index].members.append(Member(nickname: me.nickname))
        rooms[index].memberCount = rooms[index].members.count
        return rooms[index].id
    }

    // MARK: - Diary

    func feed(roomID: Int) throws -> [DiaryEntry] {
        try requireMember(of: roomID)
        // 실제 서버처럼 타임캡슐 일기도 함께 내려준다. (내용 가림은 화면에서 한다)
        return entries
            .filter { $0.roomID == roomID }
            .map(\.entry)
            .sorted { $0.createdAt > $1.createdAt }
    }

    func capsuleDiaries(roomID: Int) throws -> [DiaryEntry] {
        try requireMember(of: roomID)
        guard isCapsuleOpened(roomID: roomID) else { throw AppError.capsuleNotOpened }
        return entries
            .filter { $0.roomID == roomID && $0.entry.visibility == .capsule }
            .map(\.entry)
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addEntry(_ draft: NewDiaryDraft) throws -> Int {
        let me = try requireMember(of: draft.roomID)
        if draft.visibility == .capsule, isCapsuleOpened(roomID: draft.roomID) {
            throw AppError.capsuleAlreadyOpened
        }
        let entry = DiaryEntry(
            id: makeID(), authorNickname: me.nickname, text: draft.text,
            photoURL: nil, photoData: draft.photoData,
            visibility: draft.visibility, createdAt: now
        )
        entries.append(StoredEntry(roomID: draft.roomID, entry: entry))
        return entry.id
    }

    // MARK: - Capsule

    func capsuleInfo(roomID: Int) throws -> CapsuleInfo {
        try requireMember(of: roomID)
        guard let room = rooms.first(where: { $0.id == roomID }), let capsule = room.capsule else { throw AppError.notFound }
        let submitted = Set(entries.filter { $0.roomID == roomID && $0.entry.visibility == .capsule }.map(\.entry.authorNickname))
        return CapsuleInfo(
            roomID: roomID,
            title: capsule.title,
            openAt: capsule.openAt,
            isOpened: capsule.status(at: now) == .opened,
            members: room.members.map { MemberProgress(nickname: $0.nickname, hasSubmitted: submitted.contains($0.nickname)) }
        )
    }

    // MARK: - Helpers

    @discardableResult
    private func requireMember(of roomID: Int) throws -> User {
        let me = try requireMe()
        guard let room = rooms.first(where: { $0.id == roomID }) else { throw AppError.notFound }
        guard room.members.contains(where: { $0.nickname == me.nickname }) else { throw AppError.forbidden(nil) }
        return me
    }

    private func requireMe() throws -> User {
        guard let user = session.user else { throw AppError.invalidCredentials }
        return user
    }

    private func isCapsuleOpened(roomID: Int) -> Bool {
        guard let capsule = rooms.first(where: { $0.id == roomID })?.capsule else { return false }
        return capsule.status(at: now) == .opened
    }

    private func makeID() -> Int {
        nextID += 1
        return nextID
    }

    private func makeInviteCode() -> String {
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        while true {
            let suffix = String((0..<4).compactMap { _ in letters.randomElement() })
            let code = "JAM-\(suffix)"
            if !rooms.contains(where: { $0.inviteCode == code }) { return code }
        }
    }

    private static func normalize(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    // MARK: - Seed

    private func seed() {
        let day: TimeInterval = 86_400
        let hour: TimeInterval = 3_600
        let me = "나연", minji = "민지", seojun = "서준"

        func room(_ id: Int, _ title: String, start: TimeInterval, end: TimeInterval, code: String, members: [String], limit: Int, opensAfter: TimeInterval) -> TripRoom {
            TripRoom(
                id: id, title: title,
                startDate: now.addingTimeInterval(start), endDate: now.addingTimeInterval(end),
                inviteCode: code,
                members: members.map { Member(nickname: $0) },
                memberCount: members.count, memberLimit: limit,
                capsule: TimeCapsule(title: TimeCapsule.defaultTitle(forRoom: title), openAt: now.addingTimeInterval(opensAfter))
            )
        }

        // 부산 여행: 진행 중, 타임캡슐 잠금
        let busan = room(1, "부산 여행", start: -1 * day, end: 2 * day, code: "JAM-4F7K", members: [minji, seojun, me], limit: 3, opensAfter: 2 * day + 4 * hour)
        // 제주 가을 여행: 끝났고 타임캡슐 열림
        let jeju = room(2, "제주 가을 여행", start: -40 * day, end: -37 * day, code: "JAM-9X2P", members: [me, minji, seojun], limit: 4, opensAfter: -36 * day)
        // 강릉 당일치기
        let gangneung = room(3, "강릉 당일치기", start: -70 * day, end: -70 * day, code: "JAM-3C5D", members: [me, minji], limit: 2, opensAfter: -69 * day)
        // 속초 여행: 아직 참여하지 않은 방 (초대 코드 입력 데모용)
        let sokcho = room(4, "속초 여행", start: 10 * day, end: 12 * day, code: "JAM-8M2Q", members: [minji, seojun], limit: 3, opensAfter: 12 * day + 8 * hour)
        rooms = [busan, jeju, gangneung, sokcho]

        func entry(_ room: TripRoom, _ author: String, _ text: String, _ visibility: DiaryVisibility, ago: TimeInterval) -> StoredEntry {
            StoredEntry(roomID: room.id, entry: DiaryEntry(
                id: makeID(), authorNickname: author, text: text, photoURL: nil, photoData: nil,
                visibility: visibility, createdAt: now.addingTimeInterval(-ago)
            ))
        }
        entries = [
            entry(busan, minji, "해운대에 도착했다! 날씨가 정말 좋다.", .friends, ago: 5 * 60),
            entry(busan, seojun, "숙소 앞 편의점에서 산 간식 파티 시작.", .friends, ago: hour),
            entry(busan, minji, "출발 전 기차역에서 한 컷. 설렌다!", .friends, ago: 26 * hour),
            entry(busan, minji, "가장 기억에 남는 순간은 해운대 노을. 다들 말없이 바다만 바라보던 그 5분이 좋았다.", .capsule, ago: 3 * hour),
            entry(busan, seojun, "돼지국밥 먹고 나서 친구들 표정이 아직도 생각난다. 이런 게 여행이지.", .capsule, ago: 2 * hour),

            entry(jeju, me, "성산일출봉 도착! 바람이 엄청 세다.", .friends, ago: 39 * day),
            entry(jeju, minji, "흑돼지 구이 먹는 중. 줄 서길 잘했다.", .friends, ago: 39 * day - 3 * hour),
            entry(jeju, me, "숙소에서 밤새 나눈 이야기가 이번 여행의 진짜 하이라이트였다.", .capsule, ago: 37 * day),
            entry(jeju, minji, "돌담길 걷던 오후가 제일 좋았어. 다음에도 같이 오자.", .capsule, ago: 37 * day + hour),
            entry(jeju, seojun, "솔직히 길 잃은 게 제일 웃겼다.", .capsule, ago: 37 * day + 2 * hour),

            entry(gangneung, me, "경포대 바다 색이 너무 예뻤다.", .friends, ago: 70 * day),
            entry(gangneung, minji, "초당 순두부는 진짜 인정.", .capsule, ago: 70 * day - hour)
        ]
    }
}
