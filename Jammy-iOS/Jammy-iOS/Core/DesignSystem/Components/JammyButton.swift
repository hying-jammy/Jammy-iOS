import SwiftUI

/// 높이 48 · 라운드 14. 한 화면에 Primary 는 하나만.
struct JammyButton: View {
    enum Kind { case primary, soft, secondary, ghost }

    let title: String
    var kind: Kind = .primary
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(JammyButtonStyle(kind: kind))
    }
}

private struct JammyButtonStyle: ButtonStyle {
    let kind: JammyButton.Kind
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard(.semibold, size: 15))
            .foregroundStyle(foreground)
            .frame(height: 48)
            .background(background(isPressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        guard isEnabled else { return Color(.jammyTextTertiary) }
        switch kind {
        case .primary: return .white
        case .soft, .ghost: return Color(.jammyPrimary)
        case .secondary: return Color(.jammyTextPrimary)
        }
    }

    private func background(isPressed: Bool) -> Color {
        guard isEnabled else { return kind == .ghost ? .clear : Color(.jammyDisabled) }
        switch kind {
        case .primary: return Color(isPressed ? .jammyPrimaryPressed : .jammyPrimary)
        case .soft: return Color(.jammyPrimarySoft)
        case .secondary: return Color(.jammySecondary)
        case .ghost: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        JammyButton(title: "시작하기") {}
        JammyButton(title: "이미 계정이 있어요", kind: .soft) {}
        JammyButton(title: "링크 공유", kind: .secondary, systemImage: "link") {}
        JammyButton(title: "건너뛰기", kind: .ghost) {}
        JammyButton(title: "아직 열 수 없어요") {}.disabled(true)
    }
    .padding(20)
    .background(Color(.jammyBackground))
}
