import SwiftUI

extension View {
    /// 화면 공통 스타일: 크림 배경 + 시스템 내비게이션 바 숨김 (커스텀 JammyTopBar 사용).
    func jammyScreenStyle() -> some View {
        self
            .background(Color(.jammyBackground).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// 화면 상단의 큰 제목 + 설명.
struct ScreenIntro: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.pretendard(.extrabold, size: 26, relativeTo: .title))
                .foregroundStyle(Color(.jammyTextPrimary))
            if let subtitle {
                Text(subtitle)
                    .font(.pretendard(.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(Color(.jammyTextSecondary))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 날짜/시간 선택 필드 (라벨 + 아이콘 + 컴팩트 DatePicker).
struct JammyDateField: View {
    let title: String
    @Binding var selection: Date
    var systemImage = "calendar"
    var components: DatePickerComponents = .date
    var range: PartialRangeFrom<Date>?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color(.jammyTextPrimary))
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(.jammyTextTertiary))
                picker
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .tint(Color(.jammyPrimary))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(.jammyBorder), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var picker: some View {
        if let range {
            DatePicker("", selection: $selection, in: range, displayedComponents: components)
        } else {
            DatePicker("", selection: $selection, displayedComponents: components)
        }
    }
}

/// 체크박스 + 설명 한 줄.
struct JammyCheckboxRow: View {
    @Binding var isOn: Bool
    let text: String

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(isOn ? Color(.jammyPrimary) : Color(.jammySurface), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay {
                        if !isOn {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Color(.jammyBorder), lineWidth: 1.5)
                        }
                    }
                    .opacity(1)
                Text(text)
                    .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(.jammyTextSecondary))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
