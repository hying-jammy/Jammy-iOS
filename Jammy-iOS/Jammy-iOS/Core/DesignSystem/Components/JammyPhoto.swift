import SwiftUI
import UIKit

/// 실제 사진이 들어가기 전 쓰는 잼 일러스트 자리표시자. 크기에 비례해 그려진다.
struct PhotoPlaceholder: View {
    enum Tone { case sunny, pink, green }

    var tone: Tone = .sunny

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .topLeading) {
                background
                Circle()
                    .fill(Color(.jammySecondary))
                    .frame(width: h * 0.28, height: h * 0.28)
                    .offset(x: w * 0.68, y: h * 0.14)
                Ellipse()
                    .fill(Color(.jammyAccentGreen).opacity(0.55))
                    .frame(width: w * 1.1, height: h * 0.7)
                    .offset(x: -w * 0.05, y: h * 0.62)
                Ellipse()
                    .fill(Color(.jammyAccentPink).opacity(0.6))
                    .frame(width: w * 0.8, height: h * 0.6)
                    .offset(x: w * 0.4, y: h * 0.74)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    private var background: Color {
        switch tone {
        case .sunny: Color(.jammySecondarySoft)
        case .pink: Color(.jammyPrimarySoft)
        case .green: Color(.jammyGreenSoft)
        }
    }
}

/// 사진 데이터(또는 서버 URL)가 있으면 사진을, 없으면 자리표시자를 보여준다.
/// 크기와 모서리는 호출하는 쪽에서 정한다.
struct JammyPhoto: View {
    var data: Data?
    var url: URL?
    var tone: PhotoPlaceholder.Tone = .sunny

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Color.clear
                .overlay { Image(uiImage: image).resizable().scaledToFill() }
                .clipped()
        } else if let url {
            Color.clear
                .overlay {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            PhotoPlaceholder(tone: tone)
                        }
                    }
                }
                .clipped()
        } else {
            PhotoPlaceholder(tone: tone)
        }
    }
}

#Preview {
    HStack {
        PhotoPlaceholder(tone: .sunny).frame(width: 100, height: 75).clipShape(RoundedRectangle(cornerRadius: 16))
        PhotoPlaceholder(tone: .pink).frame(width: 100, height: 75).clipShape(RoundedRectangle(cornerRadius: 16))
        PhotoPlaceholder(tone: .green).frame(width: 100, height: 75).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .padding()
}
