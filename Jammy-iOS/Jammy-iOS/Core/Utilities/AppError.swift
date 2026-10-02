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
    case notFound
    case unknown(String)

    init(_ error: Error) {
        if let appError = error as? AppError {
            self = appError
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
        case .notFound: "찾는 정보가 없어요."
        case .unknown(let message): message
        }
    }
}
