import Foundation

struct User: Identifiable, Hashable {
    let id: UUID
    var nickname: String
    var email: String
}

/// 여행 방 참여자.
struct Member: Identifiable, Hashable {
    let id: UUID
    var nickname: String
    var isOwner: Bool = false

    /// 아바타에 표시할 이니셜 (닉네임 첫 글자)
    var initial: String { String(nickname.prefix(1)) }
}
