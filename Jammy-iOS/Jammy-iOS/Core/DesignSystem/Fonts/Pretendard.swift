import SwiftUI

/// Pretendard 폰트 파일은 `Resources/Fonts` 에 있고, `Info.plist` 의 `UIAppFonts` 로 시스템이 자동 등록한다.
/// (코드로 등록할 필요 없음. 폰트를 추가하면 Info.plist 에도 파일명을 추가해야 한다.)
enum PretendardFont {
    /// 값은 폰트의 PostScript 이름이다.
    enum Weight: String {
        case regular = "Pretendard-Regular"
        case medium = "Pretendard-Medium"
        case semibold = "Pretendard-SemiBold"
        case bold = "Pretendard-Bold"
        case extrabold = "Pretendard-ExtraBold"
    }
}

extension Font {
    /// Pretendard. 크기는 Dynamic Type 에 맞춰 함께 조정된다.
    static func pretendard(
        _ weight: PretendardFont.Weight,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: textStyle)
    }
}
