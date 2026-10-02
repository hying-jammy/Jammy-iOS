import SwiftUI

/// Jammy 의 상징 잼 병. 초기 화면, 초대 코드, 타임캡슐 등에 쓴다.
/// `label` 은 병 몸통 가운데에 놓인다. (예: 초대 코드 라벨, 자물쇠)
struct JamJarView<Label: View>: View {
    var width: CGFloat = 174
    @ViewBuilder var label: Label

    private var k: CGFloat { width / 120 }

    private let jam: [(color: Color, x: CGFloat, y: CGFloat, d: CGFloat)] = [
        (Color(.jammyPrimary), 14, 92, 18),
        (Color(.jammyAccentPink), 44, 106, 16),
        (Color(.jammySecondary), 86, 98, 20),
        (Color(.jammyAccentGreen), 22, 66, 14),
        (Color(.jammySecondarySoft), 88, 62, 16),
        (Color(.jammyPrimarySoft), 40, 60, 14),
        (Color(.jammyAccentPink), 100, 78, 12)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 병 몸통
            RoundedRectangle(cornerRadius: 32 * k, style: .continuous)
                .fill(Color(.jammySurface))
                .overlay {
                    RoundedRectangle(cornerRadius: 32 * k, style: .continuous)
                        .strokeBorder(Color(.jammyBorder), lineWidth: 2)
                }
                .shadow(color: Color(.jammyPrimary).opacity(0.12), radius: 10, y: 8)
                .frame(width: 120 * k, height: 118 * k)
                .offset(y: 24 * k)

            // 잼 알갱이
            ForEach(jam.indices, id: \.self) { index in
                let item = jam[index]
                Circle()
                    .fill(item.color)
                    .frame(width: item.d * k, height: item.d * k)
                    .offset(x: item.x * k, y: item.y * k)
            }

            // 뚜껑
            RoundedRectangle(cornerRadius: 8 * k, style: .continuous)
                .fill(Color(.jammyPrimary))
                .frame(width: 84 * k, height: 22 * k)
                .offset(x: 18 * k)

            label
                .frame(width: 120 * k, height: 118 * k)
                .offset(y: 24 * k)
        }
        .frame(width: 120 * k, height: 142 * k, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

extension JamJarView where Label == EmptyView {
    init(width: CGFloat = 174) {
        self.init(width: width) { EmptyView() }
    }
}

#Preview {
    HStack(spacing: 32) {
        JamJarView(width: 120)
        JamJarView(width: 140) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(.jammyPrimary))
                .frame(width: 40, height: 40)
                .background(Color(.jammySurface), in: Circle())
        }
    }
    .padding(40)
    .background(Color(.jammyBackground))
}
