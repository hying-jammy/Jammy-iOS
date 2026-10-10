import Foundation

// 서버 명세(Notion "API 명세서")의 요청/응답 모양 그대로의 타입.
// 날짜는 LocalDate/LocalDateTime 문자열이라 String 으로 받고, Mapper 에서 Date 로 바꾼다.

// MARK: - 인증

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct LoginResponseDTO: Decodable {
    let userId: Int
    let nickname: String
}

struct SignUpRequestDTO: Encodable {
    let nickname: String
    let email: String
    let password: String
}

// MARK: - 방

struct MemberDTO: Decodable {
    let nickname: String
}

/// GET /api/v1/users/{userId}/rooms
struct RoomListItemDTO: Decodable {
    let roomId: Int
    let title: String
    let inviteCode: String
    let startDate: String
    let endDate: String
    let memberCount: Int
    let timeCapsuleOpenAt: String
}

/// GET /api/v1/rooms/{roomId}
struct RoomDetailDTO: Decodable {
    let roomId: Int
    let title: String
    let inviteCode: String
    let startDate: String
    let endDate: String
    let members: [MemberDTO]
    let timeCapsuleOpenAt: String
}

/// GET /api/v1/rooms/invite-code/{inviteCode}
struct InviteLookupDTO: Decodable {
    let roomId: Int
    let title: String
    let startDate: String
    let endDate: String
    let memberCount: Int
    let memberLimit: Int
    let members: [MemberDTO]
}

/// POST /api/v1/rooms
struct CreateRoomRequestDTO: Encodable {
    let userId: Int
    let title: String
    let startDate: String
    let endDate: String
    let memberLimit: Int
    let timeCapsuleOpenAt: String
}

struct CreateRoomResponseDTO: Decodable {
    let roomId: Int
    let inviteCode: String
    let title: String
    let startDate: String
    let endDate: String
    let memberLimit: Int
    let timeCapsuleOpenAt: String
}

/// POST /api/v1/rooms/join
struct JoinRoomRequestDTO: Encodable {
    let userId: Int
    let inviteCode: String
}

struct JoinRoomResponseDTO: Decodable {
    let roomId: Int
}

// MARK: - 일기

/// 일기 목록(공개 / 타임캡슐 공통). type: PUBLIC | TIME_CAPSULE
struct DiaryDTO: Decodable {
    let diaryId: Int
    let nickname: String
    let content: String
    let imageUrl: String?
    let type: String
    let createdAt: String
}

struct CreateDiaryResponseDTO: Decodable {
    let diaryId: Int
}

/// GET /api/v1/rooms/{roomId}/time-capsule/diaries
///
/// 명세는 배열인데 실제 서버는 `{ memberCount, diaryCount, diaries: [...] }` 객체로 내려준다. 두 형태를 모두 받는다.
struct CapsuleDiariesDTO: Decodable {
    let diaries: [DiaryDTO]

    private enum CodingKeys: String, CodingKey { case diaries }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([DiaryDTO].self) {
            diaries = array
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        diaries = try container.decode([DiaryDTO].self, forKey: .diaries)
    }
}

// MARK: - 타임캡슐

/// GET /api/v1/rooms/{roomId}/time-capsule
///
/// 실제 서버 응답이 명세 예시와 달라서 두 가지 표기를 모두 받는다.
/// - 제목: `timeCapsuleName`(실제 서버) / `timeCapsuleTitle`(명세)
/// - 작성 여부: `hasWritten`(실제 서버) / `hasTimeCapsuleDiary`(명세)
struct CapsuleInfoDTO: Decodable {
    struct MemberProgressDTO: Decodable {
        let nickname: String
        let hasSubmitted: Bool

        private enum CodingKeys: String, CodingKey {
            case nickname, hasWritten, hasTimeCapsuleDiary
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            nickname = try container.decode(String.self, forKey: .nickname)
            hasSubmitted = try container.decodeIfPresent(Bool.self, forKey: .hasWritten)
                ?? container.decodeIfPresent(Bool.self, forKey: .hasTimeCapsuleDiary)
                ?? false
        }
    }

    let roomId: Int
    let title: String?
    /// LOCKED | OPENED
    let timeCapsuleStatus: String
    let timeCapsuleOpenAt: String
    let members: [MemberProgressDTO]

    private enum CodingKeys: String, CodingKey {
        case roomId, timeCapsuleName, timeCapsuleTitle, timeCapsuleStatus, timeCapsuleOpenAt, members
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roomId = try container.decode(Int.self, forKey: .roomId)
        title = try container.decodeIfPresent(String.self, forKey: .timeCapsuleName)
            ?? container.decodeIfPresent(String.self, forKey: .timeCapsuleTitle)
        timeCapsuleStatus = try container.decode(String.self, forKey: .timeCapsuleStatus)
        timeCapsuleOpenAt = try container.decode(String.self, forKey: .timeCapsuleOpenAt)
        members = try container.decode([MemberProgressDTO].self, forKey: .members)
    }
}
