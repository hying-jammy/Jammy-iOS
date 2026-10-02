import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    var canSubmit: Bool {
        email.contains("@") && !password.isEmpty && !isSubmitting
    }

    /// 로그인에 성공하면 true.
    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await authRepository.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
            return true
        } catch {
            errorMessage = AppError(error).errorDescription
            return false
        }
    }
}

@MainActor
@Observable
final class SignUpViewModel {
    var nickname = ""
    var email = ""
    var password = ""
    var agreedToTerms = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    private var trimmedNickname: String { nickname.trimmingCharacters(in: .whitespaces) }

    var isEmailValid: Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !email.contains(" ")
    }

    /// 8자 이상, 영문과 숫자를 모두 포함
    var isPasswordValid: Bool {
        password.count >= 8
            && password.contains(where: \.isLetter)
            && password.contains(where: \.isNumber)
    }

    /// 입력을 시작한 뒤에만 보여주는 에러 문구
    var emailError: String? {
        email.isEmpty || isEmailValid ? nil : "이메일 형식을 확인해 주세요."
    }

    var passwordError: String? {
        password.isEmpty || isPasswordValid ? nil : "8자 이상, 영문과 숫자를 함께 사용해 주세요."
    }

    var canSubmit: Bool {
        !trimmedNickname.isEmpty && isEmailValid && isPasswordValid && agreedToTerms && !isSubmitting
    }

    /// 가입에 성공하면 true.
    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await authRepository.signUp(nickname: trimmedNickname, email: email, password: password)
            return true
        } catch {
            errorMessage = AppError(error).errorDescription
            return false
        }
    }
}
