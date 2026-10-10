import Foundation

/// 로그인한 사용자. 서버는 userId 와 닉네임만 내려준다. (토큰 없음)
struct User: Identifiable, Hashable {
    let id: Int
    var nickname: String
}

/// 여행 방 참여자. 서버가 닉네임만 내려주므로 닉네임이 식별자다.
struct Member: Identifiable, Hashable {
    var nickname: String
    var id: String { nickname }

    /// 아바타에 표시할 이니셜 (닉네임 첫 글자)
    var initial: String { String(nickname.prefix(1)) }
}
