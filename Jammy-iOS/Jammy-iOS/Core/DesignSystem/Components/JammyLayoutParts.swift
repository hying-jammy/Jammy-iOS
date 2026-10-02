import SwiftUI

/// 섹션 제목 + 우측 보조 텍스트.
struct SectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(.bold, size: 18, relativeTo: .headline))
                .foregroundStyle(Color(.jammyTextPrimary))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color(.jammyTextTertiary))
            }
        }
    }
}

/// 안내 배너 (옐로우 소프트).
struct NoticeBanner: View {
    var systemImage = "key"
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.jammyYellowText))
                .frame(width: 32, height: 32)
                .background(Color(.jammySurface), in: Circle())
            Text(text)
                .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color(.jammyYellowText))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(.jammySecondarySoft), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// 방 화면의 피드 / 기록 전환 탭.
enum RoomTab: String, CaseIterable, Identifiable {
    case feed = "피드"
    case records = "기록"

    var id: String { rawValue }
}

struct RoomTabs: View {
    @Binding var selection: RoomTab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RoomTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { selection = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color(selection == tab ? .jammyTextPrimary : .jammyTextSecondary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color(.jammySurface))
                                    .shadow(color: Color(.jammyTextPrimary).opacity(0.06), radius: 3, y: 2)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color(.jammyNeutralChip), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    @Previewable @State var tab = RoomTab.feed
    VStack(spacing: 16) {
        SectionHeader(title: "참여 중인 여행", trailing: "3개")
        RoomTabs(selection: $tab)
        NoticeBanner(text: "방을 만들면 친구들에게 보낼 초대 코드가 발급돼요.")
    }
    .padding(20)
    .background(Color(.jammyBackground))
}
