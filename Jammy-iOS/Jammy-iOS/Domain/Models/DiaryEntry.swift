import Foundation

enum DiaryVisibility: Hashable {
    /// 공개 일기: 작성 즉시 그룹원 전체에게 보인다. (서버 type: PUBLIC)
    case friends
    /// 비밀 일기: 타임캡슐 공개 전까지 보이지 않는다. (서버 type: TIME_CAPSULE)
    case capsule
}

struct DiaryEntry: Identifiable, Hashable {
    let id: Int
    /// 서버가 작성자 id 없이 닉네임만 내려준다.
    var authorNickname: String
    var text: String
    /// 서버가 내려주는 사진 URL
    var photoURL: URL?
    /// Mock 에서만 쓰는 로컬 사진 데이터
    var photoData: Data?
    var visibility: DiaryVisibility
    var createdAt: Date
}

struct NewDiaryDraft {
    var roomID: Int
    var text: String
    /// 사진은 최대 1장
    var photoData: Data?
    var visibility: DiaryVisibility
}
