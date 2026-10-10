import Foundation

/// 타임캡슐. MVP 에서는 방당 1개.
struct TimeCapsule: Hashable {
    enum Status { case locked, opened }

    var title: String
    var openAt: Date

    /// 서버가 방 정보에는 타임캡슐 제목을 주지 않아서 방 제목으로 만든 기본 제목.
    static func defaultTitle(forRoom title: String) -> String { "\(title) 마지막 밤" }

    /// 화면 갱신용 판단. 실제 공개 여부의 기준은 서버(`CapsuleInfo.isOpened`)다.
    func status(at now: Date) -> Status {
        now >= openAt ? .opened : .locked
    }
}

/// 타임캡슐 참여자별 비밀 일기 작성 여부.
struct MemberProgress: Identifiable, Hashable {
    var nickname: String
    var hasSubmitted: Bool
    var id: String { nickname }
}

/// 타임캡슐 상세 화면에 필요한 정보 (공개 전/후 공통).
struct CapsuleInfo: Hashable {
    var roomID: Int
    var title: String
    var openAt: Date
    /// 서버가 판단한 공개 여부
    var isOpened: Bool
    var members: [MemberProgress]
}
