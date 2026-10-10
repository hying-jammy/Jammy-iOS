import Foundation

// DTO → Domain 변환. 날짜 파싱에 실패하면 응답 형식 오류(.decoding)로 처리한다.

private func parseDate(_ string: String) throws -> Date {
    guard let date = ServerDate.date(string) else { throw AppError.decoding }
    return date
}

private func parseDateTime(_ string: String) throws -> Date {
    guard let date = ServerDate.dateTime(string) else { throw AppError.decoding }
    return date
}

extension RoomListItemDTO {
    func toDomain() throws -> TripRoom {
        TripRoom(
            id: roomId,
            title: title,
            startDate: try parseDate(startDate),
            endDate: try parseDate(endDate),
            inviteCode: inviteCode,
            members: [],
            memberCount: memberCount,
            memberLimit: nil,
            capsule: TimeCapsule(title: TimeCapsule.defaultTitle(forRoom: title), openAt: try parseDateTime(timeCapsuleOpenAt))
        )
    }
}

extension RoomDetailDTO {
    func toDomain() throws -> TripRoom {
        TripRoom(
            id: roomId,
            title: title,
            startDate: try parseDate(startDate),
            endDate: try parseDate(endDate),
            inviteCode: inviteCode,
            members: members.map { Member(nickname: $0.nickname) },
            memberCount: members.count,
            memberLimit: nil,
            capsule: TimeCapsule(title: TimeCapsule.defaultTitle(forRoom: title), openAt: try parseDateTime(timeCapsuleOpenAt))
        )
    }
}

extension InviteLookupDTO {
    /// 이 응답에는 초대 코드와 타임캡슐 정보가 없어서 호출한 코드를 함께 받는다.
    func toDomain(inviteCode: String) throws -> TripRoom {
        TripRoom(
            id: roomId,
            title: title,
            startDate: try parseDate(startDate),
            endDate: try parseDate(endDate),
            inviteCode: inviteCode,
            members: members.map { Member(nickname: $0.nickname) },
            memberCount: memberCount,
            memberLimit: memberLimit,
            capsule: nil
        )
    }
}

extension CreateRoomResponseDTO {
    func toDomain(creator: User) throws -> TripRoom {
        TripRoom(
            id: roomId,
            title: title,
            startDate: try parseDate(startDate),
            endDate: try parseDate(endDate),
            inviteCode: inviteCode,
            members: [Member(nickname: creator.nickname)],
            memberCount: 1,
            memberLimit: memberLimit,
            capsule: TimeCapsule(title: TimeCapsule.defaultTitle(forRoom: title), openAt: try parseDateTime(timeCapsuleOpenAt))
        )
    }
}

extension DiaryDTO {
    func toDomain() throws -> DiaryEntry {
        DiaryEntry(
            id: diaryId,
            authorNickname: nickname,
            text: content,
            photoURL: imageUrl.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            photoData: nil,
            visibility: type == "TIME_CAPSULE" ? .capsule : .friends,
            createdAt: try parseDateTime(createdAt)
        )
    }
}

extension CapsuleInfoDTO {
    func toDomain(fallbackTitle: String = "타임캡슐") throws -> CapsuleInfo {
        CapsuleInfo(
            roomID: roomId,
            title: title ?? fallbackTitle,
            openAt: try parseDateTime(timeCapsuleOpenAt),
            isOpened: timeCapsuleStatus == "OPENED",
            members: members.map { MemberProgress(nickname: $0.nickname, hasSubmitted: $0.hasSubmitted) }
        )
    }
}
