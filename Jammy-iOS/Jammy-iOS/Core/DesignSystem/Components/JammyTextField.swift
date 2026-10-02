import SwiftUI

/// 높이 48 · 라운드 14. 포커스 시 빨간 2px 테두리와 링, 에러 시 빨간 테두리.
struct JammyTextField: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var isSecure = false
    var hint: String?
    var errorMessage: String?
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never

    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color(.jammyTextPrimary))
            }

            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(.jammyTextTertiary))
                }
                field
                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(.jammyTextTertiary))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(isRevealed ? "비밀번호 숨기기" : "비밀번호 보기")
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, isSecure ? 4 : 16)
            .frame(height: 48)
            .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused || errorMessage != nil ? 2 : 1)
            }
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(.jammyPrimary).opacity(0.10), lineWidth: 4)
                        .padding(-2)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.pretendard(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color(.jammyError))
            } else if let hint {
                Text(hint)
                    .font(.pretendard(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color(.jammyTextTertiary))
            }
        }
    }

    @ViewBuilder
    private var field: some View {
        Group {
            if isSecure && !isRevealed {
                SecureField("", text: $text, prompt: prompt)
            } else {
                TextField("", text: $text, prompt: prompt)
            }
        }
        .font(.pretendard(.medium, size: 16))
        .foregroundStyle(Color(.jammyTextPrimary))
        .keyboardType(keyboard)
        .textContentType(textContentType)
        .textInputAutocapitalization(autocapitalization)
        .autocorrectionDisabled()
        .focused($isFocused)
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(Color(.jammyTextTertiary))
    }

    private var borderColor: Color {
        if errorMessage != nil { return Color(.jammyError) }
        return Color(isFocused ? .jammyPrimary : .jammyBorder)
    }
}

#Preview {
    @Previewable @State var email = ""
    @Previewable @State var password = "secret"
    VStack(spacing: 16) {
        JammyTextField(title: "이메일", placeholder: "example@jammy.com", text: $email, systemImage: "envelope")
        JammyTextField(title: "비밀번호", placeholder: "비밀번호를 입력해 주세요", text: $password, systemImage: "lock", isSecure: true, hint: "영문과 숫자를 함께 사용해 주세요.")
        JammyTextField(title: "닉네임", placeholder: "친구들에게 보일 이름", text: $email, systemImage: "person", errorMessage: "닉네임을 입력해 주세요.")
    }
    .padding(20)
    .background(Color(.jammyBackground))
}
