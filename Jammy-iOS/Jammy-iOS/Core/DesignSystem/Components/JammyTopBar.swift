import SwiftUI

/// 원형 아이콘 버튼 (40pt 시각 크기, 44pt 터치 영역).
struct JammyIconButton: View {
    enum Style { case outline, soft }

    let systemImage: String
    var style: Style = .outline
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(style == .outline ? .jammyTextPrimary : .jammyPrimary))
                .frame(width: 40, height: 40)
                .background(Color(style == .outline ? .jammySurface : .jammyPrimarySoft), in: Circle())
                .overlay {
                    if style == .outline {
                        Circle().strokeBorder(Color(.jammyBorder), lineWidth: 1)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// 뒤로가기 + 가운데 제목. 우측은 비워 균형을 맞춘다.
struct JammyTopBar<Trailing: View>: View {
    let title: String?
    var backImage = "chevron.left"
    var backLabel = "뒤로가기"
    let onBack: (() -> Void)?
    @ViewBuilder let trailing: Trailing

    init(
        title: String? = nil,
        backImage: String = "chevron.left",
        backLabel: String = "뒤로가기",
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.backImage = backImage
        self.backLabel = backLabel
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            HStack {
                if let onBack {
                    JammyIconButton(systemImage: backImage, accessibilityLabel: backLabel, action: onBack)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
                Spacer()
                trailing
            }
            if let title {
                Text(title)
                    .font(.pretendard(.bold, size: 17, relativeTo: .headline))
                    .foregroundStyle(Color(.jammyTextPrimary))
            }
        }
        .frame(height: 48)
    }
}

extension JammyTopBar where Trailing == EmptyView {
    init(
        title: String? = nil,
        backImage: String = "chevron.left",
        backLabel: String = "뒤로가기",
        onBack: (() -> Void)? = nil
    ) {
        self.init(title: title, backImage: backImage, backLabel: backLabel, onBack: onBack) { EmptyView() }
    }
}

#Preview {
    VStack {
        JammyTopBar(title: "여행 방 만들기", onBack: {})
        JammyTopBar(onBack: {}) { JammyChip(title: "초대 코드 JAM-4F7K", kind: .yellow, systemImage: "key") }
    }
    .padding(.horizontal, 20)
    .background(Color(.jammyBackground))
}
