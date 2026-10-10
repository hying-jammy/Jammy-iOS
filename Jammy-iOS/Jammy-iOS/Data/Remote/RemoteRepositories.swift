import Foundation
import UIKit

// 서버 명세(Notion "API 명세서")에 맞춘 Remote 구현체.
// 서버가 토큰을 발급하지 않아, 사용자 식별은 로그인 때 받은 userId 를 요청 경로/본문에 담아 보낸다.

private extension String {
    /// 경로 한 조각을 퍼센트 인코딩한다. ("/" 도 인코딩)
    var pathSegment: String {
        addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? self
    }
}

private func requireUser(_ session: SessionStore) throws -> User {
    guard let user = session.user else { throw AppError.invalidCredentials }
    return user
}

// MARK: - 인증

struct RemoteAuthRepository: AuthRepository {
    let client: APIClient
    let session: SessionStore

    func currentUser() async -> User? { session.user }

    func login(email: String, password: String) async throws -> User {
        let request = try APIRequest.json(.post, "/api/v1/auth/login", body: LoginRequestDTO(email: email, password: password))
        let response: LoginResponseDTO
        do {
            response = try await client.send(request)
        } catch AppError.notFound {
            // 가입되지 않은 이메일(404). 계정 존재 여부는 알려주지 않고 같은 문구로 안내한다.
            throw AppError.invalidCredentials
        }
        let user = User(id: response.userId, nickname: response.nickname)
        session.user = user
        return user
    }

    func signUp(nickname: String, email: String, password: String) async throws {
        let request = try APIRequest.json(.post, "/api/v1/auth/signup", body: SignUpRequestDTO(nickname: nickname, email: email, password: password))
        do {
            try await client.sendIgnoringResult(request)
        } catch AppError.conflict {
            throw AppError.emailAlreadyUsed
        }
    }

    func logout() async { session.user = nil }
}

// MARK: - 방

struct RemoteRoomRepository: RoomRepository {
    let client: APIClient
    let session: SessionStore

    func fetchMyRooms() async throws -> [TripRoom] {
        let user = try requireUser(session)
        let items: [RoomListItemDTO] = try await client.send(APIRequest(method: .get, path: "/api/v1/users/\(user.id)/rooms"))
        return try items.map { try $0.toDomain() }
    }

    func fetchRoom(id: Int) async throws -> TripRoom {
        let dto: RoomDetailDTO = try await client.send(APIRequest(method: .get, path: "/api/v1/rooms/\(id)"))
        return try dto.toDomain()
    }

    func lookupRoom(inviteCode: String) async throws -> TripRoom {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        do {
            let dto: InviteLookupDTO = try await client.send(APIRequest(method: .get, path: "/api/v1/rooms/invite-code/\(code.pathSegment)"))
            return try dto.toDomain(inviteCode: code)
        } catch AppError.notFound {
            throw AppError.invalidInviteCode
        } catch AppError.badRequest {
            throw AppError.invalidInviteCode
        }
    }

    func createRoom(_ draft: NewRoomDraft) async throws -> TripRoom {
        let user = try requireUser(session)
        let body = CreateRoomRequestDTO(
            userId: user.id,
            title: draft.title,
            startDate: ServerDate.string(fromDate: draft.startDate),
            endDate: ServerDate.string(fromDate: draft.endDate),
            memberLimit: draft.memberLimit,
            timeCapsuleOpenAt: ServerDate.string(fromDateTime: draft.capsuleOpenAt)
        )
        let response: CreateRoomResponseDTO = try await client.send(try APIRequest.json(.post, "/api/v1/rooms", body: body))
        return try response.toDomain(creator: user)
    }

    func joinRoom(inviteCode: String) async throws -> Int {
        let user = try requireUser(session)
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let request = try APIRequest.json(.post, "/api/v1/rooms/join", body: JoinRoomRequestDTO(userId: user.id, inviteCode: code))
        do {
            let response: JoinRoomResponseDTO = try await client.send(request)
            return response.roomId
        } catch AppError.notFound {
            throw AppError.invalidInviteCode
        }
    }
}

// MARK: - 일기

struct RemoteDiaryRepository: DiaryRepository {
    let client: APIClient
    let session: SessionStore

    func fetchFeed(roomID: Int) async throws -> [DiaryEntry] {
        let items: [DiaryDTO] = try await client.send(APIRequest(method: .get, path: "/api/v1/rooms/\(roomID)/diaries"))
        // 명세는 공개 일기만 준다고 했지만 실제 서버는 타임캡슐 일기(type: TIME_CAPSULE)도 섞어서 내려준다.
        // 여기서는 그대로 돌려주고, 화면(RoomMainViewModel)이 비밀 일기의 내용을 가려서 보여준다.
        return try items.map { try $0.toDomain() }.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchCapsuleDiaries(roomID: Int) async throws -> [DiaryEntry] {
        do {
            let response: CapsuleDiariesDTO = try await client.send(APIRequest(method: .get, path: "/api/v1/rooms/\(roomID)/time-capsule/diaries"))
            return try response.diaries.map { try $0.toDomain() }.sorted { $0.createdAt < $1.createdAt }
        } catch AppError.forbidden {
            throw AppError.capsuleNotOpened
        } catch AppError.conflict {
            // 명세는 403 이지만 실제 서버는 공개 전 조회에 409 를 돌려준다.
            throw AppError.capsuleNotOpened
        }
    }

    func addEntry(_ draft: NewDiaryDraft) async throws -> Int {
        let user = try requireUser(session)

        var form = MultipartForm()
        form.fields["userId"] = String(user.id)
        form.fields["content"] = draft.text
        form.fields["type"] = draft.visibility == .capsule ? "TIME_CAPSULE" : "PUBLIC"
        if let data = draft.photoData, let jpeg = Self.jpeg(from: data) {
            form.files.append(.init(name: "image", filename: "image.jpg", mimeType: "image/jpeg", data: jpeg))
        }

        let request = APIRequest(method: .post, path: "/api/v1/rooms/\(draft.roomID)/diaries", multipart: form)
        let response: CreateDiaryResponseDTO = try await client.send(request)
        return response.diaryId
    }

    /// 업로드 용량을 줄이기 위해 긴 변 1600px, JPEG 품질 0.8 로 다시 인코딩한다.
    private static func jpeg(from data: Data, maxDimension: CGFloat = 1600) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image.jpegData(compressionQuality: 0.8) }
        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - 타임캡슐

struct RemoteCapsuleRepository: CapsuleRepository {
    let client: APIClient

    func fetchCapsule(roomID: Int) async throws -> CapsuleInfo {
        let dto: CapsuleInfoDTO = try await client.send(APIRequest(method: .get, path: "/api/v1/rooms/\(roomID)/time-capsule"))
        return try dto.toDomain()
    }
}
