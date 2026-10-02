import Foundation

enum DiaryVisibility: Hashable {
    /// 공개 일기: 작성 즉시 그룹원 전체에게 보인다.
    case friends
    /// 비밀 일기: 타임캡슐 공개 전까지 작성자 본인만 볼 수 있다.
    case capsule
}

struct DiaryEntry: Identifiable, Hashable {
    let id: UUID
    let roomID: UUID
    let authorID: UUID
    var text: String
    /// 임시: 서버 연동 전까지는 선택한 사진 데이터를 그대로 들고 있는다. (API 연결 시 URL 로 교체)
    var photoData: [Data]
    var visibility: DiaryVisibility
    var createdAt: Date
}

struct NewDiaryDraft {
    var roomID: UUID
    var text: String
    var photoData: [Data]
    var visibility: DiaryVisibility
}
