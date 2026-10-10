import Foundation

/// 앱 전체에서 쓰는 도메인 수준 에러.
/// 네트워크/서버 에러는 Data 계층에서 이 타입으로 변환해 올린다.
enum AppError: LocalizedError, Equatable {
    case invalidCredentials
    case emailAlreadyUsed
    case invalidInviteCode
    case alreadyMember
    case roomFull
    case capsuleAlreadyOpened
    /// 타임캡슐 공개 시간 전에 기록을 조회했을 때
    case capsuleNotOpened
    case notFound
    /// 400: 요청 형식 오류
    case badRequest(String?)
    /// 403
    case forbidden(String?)
    /// 409: 이미 참여 중이거나 정원 초과 등
    case conflict(String?)
    case network
    case server(String?)
    case decoding
    case unknown(String)

    init(_ error: Error) {
        if let appError = error as? AppError {
            self = appError
        } else if error is URLError {
            self = .network
        } else {
            self = .unknown(error.localizedDescription)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "이메일 또는 비밀번호를 다시 확인해 주세요."
        case .emailAlreadyUsed: "이미 가입된 이메일이에요."
        case .invalidInviteCode: "초대 코드를 찾을 수 없어요."
        case .alreadyMember: "이미 참여 중인 방이에요."
        case .roomFull: "방이 가득 찼어요."
        case .capsuleAlreadyOpened: "이미 열린 타임캡슐에는 비밀 일기를 담을 수 없어요."
        case .capsuleNotOpened: "아직 타임캡슐이 열리지 않았어요."
        case .notFound: "찾는 정보가 없어요."
        case .badRequest(let message): message ?? "입력한 내용을 다시 확인해 주세요."
        case .forbidden(let message): message ?? "접근할 수 없어요."
        case .conflict(let message): message ?? "이미 참여 중이거나 정원이 가득 찬 방이에요."
        case .network: "네트워크 연결을 확인해 주세요."
        case .server(let message): message ?? "서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요."
        case .decoding: "서버 응답을 해석하지 못했어요."
        case .unknown(let message): message
        }
    }
}
