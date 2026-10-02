import SwiftUI

/// 친구 구분용 이니셜 아바타. 흰 테두리로 겹쳐 쌓을 수 있다.
struct JammyAvatar: View {
    enum Size {
        case small, medium, large

        var points: CGFloat {
            switch self {
            case .small: 32
            case .medium: 40
            case .large: 56
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: 13
            case .medium: 16
            case .large: 22
            }
        }
    }

    let initial: String
    var tone: Color = Color(.jammySecondarySoft)
    var size: Size = .small

    init(initial: String, tone: Color = Color(.jammySecondarySoft), size: Size = .small) {
        self.initial = initial
        self.tone = tone
        self.size = size
    }

    /// 참여자 id 로 색이 고정되도록 톤을 고른다.
    init(member: Member, size: Size = .small) {
        let tones = [Color(.jammyPrimarySoft), Color(.jammySecondarySoft), Color(.jammyGreenSoft)]
        self.init(initial: member.initial, tone: tones[Int(member.id.uuid.0) % tones.count], size: size)
    }

    var body: some View {
        Text(initial)
            .font(.pretendard(.bold, size: size.fontSize, relativeTo: .subheadline))
            .foregroundStyle(Color(.jammyTextPrimary))
            .frame(width: size.points, height: size.points)
            .background(tone, in: Circle())
            .overlay(Circle().strokeBorder(Color(.jammySurface), lineWidth: 2))
            .accessibilityHidden(true)
    }
}

/// 겹쳐진 아바타 줄.
struct JammyAvatarStack: View {
    let members: [Member]
    var size: JammyAvatar.Size = .medium

    var body: some View {
        HStack(spacing: -8) {
            ForEach(members) { JammyAvatar(member: $0, size: size) }
        }
    }
}

/// 기록 추가 등 화면의 주요 추가 액션. 56 · 라운드 18 · 옐로우.
struct JammyFAB: View {
    var systemImage = "plus"
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(.jammyTextPrimary))
                .frame(width: 56, height: 56)
                .background(Color(.jammySecondary), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(.jammyTextPrimary).opacity(0.08), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    HStack(spacing: 24) {
        JammyAvatar(initial: "나", size: .small)
        JammyAvatar(initial: "나", size: .medium)
        JammyAvatar(initial: "나", size: .large)
        JammyFAB(accessibilityLabel: "기록 추가") {}
    }
    .padding()
    .background(Color(.jammyBackground))
}
