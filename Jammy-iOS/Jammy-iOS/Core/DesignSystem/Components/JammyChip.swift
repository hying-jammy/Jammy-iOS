import SwiftUI

/// 높이 30 · 완전 둥근 모서리. 상태·카테고리 표시.
struct JammyChip: View {
    enum Kind { case primary, yellow, green, neutral, solid }

    let title: String
    var kind: Kind = .primary
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(title)
                .font(.pretendard(.semibold, size: 13, relativeTo: .footnote))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch kind {
        case .primary: Color(.jammyPrimary)
        case .yellow: Color(.jammyYellowText)
        case .green: Color(red: 0x5F / 255, green: 0x81 / 255, blue: 0x51 / 255)
        case .neutral: Color(.jammyTextSecondary)
        case .solid: .white
        }
    }

    private var background: Color {
        switch kind {
        case .primary: Color(.jammyPrimarySoft)
        case .yellow: Color(.jammySecondarySoft)
        case .green: Color(.jammyGreenSoft)
        case .neutral: Color(.jammyNeutralChip)
        case .solid: Color(.jammyPrimary)
        }
    }
}

#Preview {
    HStack {
        JammyChip(title: "여행 중", kind: .solid)
        JammyChip(title: "잠금", kind: .yellow, systemImage: "lock.fill")
        JammyChip(title: "열림", kind: .green)
        JammyChip(title: "완료", kind: .neutral)
        JammyChip(title: "공개", kind: .primary)
    }
    .padding()
    .background(Color(.jammyBackground))
}
