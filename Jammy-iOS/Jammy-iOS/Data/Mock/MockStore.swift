import Foundation

/// 서버 대신 메모리에 데이터를 들고 있는 Mock 저장소.
/// "방 만들기 → 홈 목록에 나타남" 같은 흐름이 앱 안에서 이어지도록 상태를 유지한다.
/// 비즈니스 규칙(비밀 일기는 공개 전 작성자만 조회 등)도 서버처럼 여기서 강제한다.
@MainActor
final class MockStore {
    private let dateProvider: DateProvider
    private var users: [User] = []
    private var rooms: [TripRoom] = []
    private var entries: [DiaryEntry] = []
    private(set) var currentUser: User?

    private let seedUser = User(id: UUID(), nickname: "나연", email: "nayeon@jammy.com")
    private let minji = User(id: UUID(), nickname: "민지", email: "minji@jammy.com")
    private let seojun = User(id: UUID(), nickname: "서준", email: "seojun@jammy.com")

    init(dateProvider: DateProvider = SystemDateProvider()) {
        self.dateProvider = dateProvider
        users = [seedUser, minji, seojun]
        seed()
    }

    private var now: Date { dateProvider.now }

    // MARK: - Auth

    func login(email: String, password: String) throws -> User {
        // 데모용 실패 케이스
        if email.lowercased() == "fail@jammy.com" { throw AppError.invalidCredentials }
        currentUser = seedUser
        return seedUser
    }

    func signUp(nickname: String, email: String, password: String) throws -> User {
        // 데모용 실패 케이스
        if email.lowercased() == "taken@jammy.com" { throw AppError.emailAlreadyUsed }
        let user = User(id: UUID(), nickname: nickname, email: email)
        users.append(user)
        currentUser = user
        return user
    }

    func logout() { currentUser = nil }

    // MARK: - Room

    func myRooms() throws -> [TripRoom] {
        let me = try requireMe()
        return rooms
            .filter { $0.member(id: me.id) != nil }
            .sorted { $0.startDate > $1.startDate }
    }

    func room(id: UUID) throws -> TripRoom {
        guard let room = rooms.first(where: { $0.id == id }) else { throw AppError.notFound }
        return room
    }

    func lookupRoom(inviteCode: String) throws -> TripRoom {
        let code = Self.normalize(inviteCode)
        guard let room = rooms.first(where: { $0.inviteCode == code }) else { throw AppError.invalidInviteCode }
        return room
    }

    func createRoom(_ draft: NewRoomDraft) throws -> TripRoom {
        let me = try requireMe()
        let room = TripRoom(
            id: UUID(),
            title: draft.title,
            startDate: draft.startDate,
            endDate: draft.endDate,
            inviteCode: makeInviteCode(),
            ownerID: me.id,
            members: [Member(id: me.id, nickname: me.nickname, isOwner: true)],
            maxMembers: draft.maxMembers,
            capsule: TimeCapsule(id: UUID(), title: "\(draft.title) 마지막 밤", openAt: draft.capsuleOpenAt)
        )
        rooms.append(room)
        return room
    }

    func joinRoom(inviteCode: String) throws -> TripRoom {
        let me = try requireMe()
        let code = Self.normalize(inviteCode)
        guard let index = rooms.firstIndex(where: { $0.inviteCode == code }) else { throw AppError.invalidInviteCode }
        if rooms[index].member(id: me.id) != nil { throw AppError.alreadyMember }
        if rooms[index].isFull { throw AppError.roomFull }
        rooms[index].members.append(Member(id: me.id, nickname: me.nickname))
        return rooms[index]
    }

    // MARK: - Diary

    func feed(roomID: UUID) throws -> [DiaryEntry] {
        try requireMember(of: roomID)
        return entries
            .filter { $0.roomID == roomID && $0.visibility == .friends }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func timeline(roomID: UUID) throws -> [DiaryEntry] {
        let me = try requireMember(of: roomID)
        let opened = isCapsuleOpened(roomID: roomID)
        return entries
            .filter { entry in
                guard entry.roomID == roomID else { return false }
                switch entry.visibility {
                case .friends: return true
                case .capsule: return opened || entry.authorID == me.id
                }
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addEntry(_ draft: NewDiaryDraft) throws -> DiaryEntry {
        let me = try requireMember(of: draft.roomID)
        if draft.visibility == .capsule, isCapsuleOpened(roomID: draft.roomID) {
            throw AppError.capsuleAlreadyOpened
        }
        let entry = DiaryEntry(
            id: UUID(), roomID: draft.roomID, authorID: me.id,
            text: draft.text, photoData: draft.photoData,
            visibility: draft.visibility, createdAt: now
        )
        entries.append(entry)
        return entry
    }

    // MARK: - Capsule

    func capsuleDetail(roomID: UUID) throws -> CapsuleDetail {
        try requireMember(of: roomID)
        let room = try room(id: roomID)
        guard let capsule = room.capsule else { throw AppError.notFound }
        let secrets = entries.filter { $0.roomID == roomID && $0.visibility == .capsule }
        let opened = capsule.status(at: now) == .opened
        return CapsuleDetail(
            room: room,
            capsule: capsule,
            submittedMemberIDs: Set(secrets.map(\.authorID)),
            entries: opened ? secrets.sorted { $0.createdAt < $1.createdAt } : []
        )
    }

    // MARK: - Helpers

    @discardableResult
    private func requireMember(of roomID: UUID) throws -> User {
        let me = try requireMe()
        let room = try room(id: roomID)
        guard room.member(id: me.id) != nil else { throw AppError.notFound }
        return me
    }

    private func requireMe() throws -> User {
        guard let currentUser else { throw AppError.invalidCredentials }
        return currentUser
    }

    private func isCapsuleOpened(roomID: UUID) -> Bool {
        guard let capsule = rooms.first(where: { $0.id == roomID })?.capsule else { return false }
        return capsule.status(at: now) == .opened
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
        let me = seedUser
        func member(_ user: User, owner: Bool = false) -> Member {
            Member(id: user.id, nickname: user.nickname, isOwner: owner)
        }

        // 부산 여행: 진행 중, 타임캡슐 잠금
        let busan = TripRoom(
            id: UUID(), title: "부산 여행",
            startDate: now.addingTimeInterval(-1 * day), endDate: now.addingTimeInterval(2 * day),
            inviteCode: "JAM-4F7K", ownerID: minji.id,
            members: [member(minji, owner: true), member(seojun), member(me)], maxMembers: 3,
            capsule: TimeCapsule(id: UUID(), title: "부산 여행 마지막 밤", openAt: now.addingTimeInterval(2 * day + 4 * hour))
        )
        // 제주 가을 여행: 끝났고 타임캡슐 열림
        let jeju = TripRoom(
            id: UUID(), title: "제주 가을 여행",
            startDate: now.addingTimeInterval(-40 * day), endDate: now.addingTimeInterval(-37 * day),
            inviteCode: "JAM-9X2P", ownerID: me.id,
            members: [member(me, owner: true), member(minji), member(seojun)], maxMembers: 4,
            capsule: TimeCapsule(id: UUID(), title: "제주 여행 마지막 밤", openAt: now.addingTimeInterval(-36 * day))
        )
        // 강릉 당일치기
        let gangneung = TripRoom(
            id: UUID(), title: "강릉 당일치기",
            startDate: now.addingTimeInterval(-70 * day), endDate: now.addingTimeInterval(-70 * day),
            inviteCode: "JAM-3C5D", ownerID: me.id,
            members: [member(me, owner: true), member(minji)], maxMembers: 2,
            capsule: TimeCapsule(id: UUID(), title: "강릉 당일치기 밤", openAt: now.addingTimeInterval(-69 * day))
        )
        // 속초 여행: 아직 참여하지 않은 방 (초대 코드 입력 데모용)
        let sokcho = TripRoom(
            id: UUID(), title: "속초 여행",
            startDate: now.addingTimeInterval(10 * day), endDate: now.addingTimeInterval(12 * day),
            inviteCode: "JAM-8M2Q", ownerID: minji.id,
            members: [member(minji, owner: true), member(seojun)], maxMembers: 3,
            capsule: TimeCapsule(id: UUID(), title: "속초 여행 마지막 밤", openAt: now.addingTimeInterval(12 * day + 8 * hour))
        )
        rooms = [busan, jeju, gangneung, sokcho]

        func entry(_ room: TripRoom, _ author: User, _ text: String, _ visibility: DiaryVisibility, ago: TimeInterval) -> DiaryEntry {
            DiaryEntry(id: UUID(), roomID: room.id, authorID: author.id, text: text, photoData: [],
                       visibility: visibility, createdAt: now.addingTimeInterval(-ago))
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
