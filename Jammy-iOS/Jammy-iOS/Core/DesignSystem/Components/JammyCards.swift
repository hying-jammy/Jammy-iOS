import SwiftUI

private extension View {
    /// 카드 공통 스타일: 흰 배경 + 1px 테두리 + 가벼운 그림자.
    func jammyCard(radius: CGFloat = 18, fill: Color = Color(.jammySurface), playful: Bool = false) -> some View {
        self
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color(.jammyBorder), lineWidth: 1)
            }
            .shadow(
                color: playful ? Color(.jammyPrimary).opacity(0.12) : Color(.jammyTextPrimary).opacity(0.06),
                radius: playful ? 10 : 3,
                y: playful ? 8 : 2
            )
    }
}

/// 홈의 대표 여행 카드 (진행 중 + 타임캡슐 상태).
struct FeaturedTripCard: View {
    let title: String
    let meta: String
    let statusTitle: String
    var statusKind: JammyChip.Kind = .solid
    let capsuleTitle: String
    let capsuleSubtitle: String
    var dDay: String?

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                PhotoPlaceholder(tone: .sunny)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    JammyChip(title: statusTitle, kind: statusKind)
                    Text(title)
                        .font(.pretendard(.bold, size: 20, relativeTo: .title3))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text(meta)
                        .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color(.jammyTextSecondary))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.jammyYellowText))
                    .frame(width: 32, height: 32)
                    .background(Color(.jammySecondarySoft), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(capsuleTitle)
                        .font(.pretendard(.semibold, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text(capsuleSubtitle)
                        .font(.pretendard(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(.jammyTextSecondary))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let dDay {
                    Text(dDay)
                        .font(.pretendard(.extrabold, size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color(.jammyPrimary))
                }
            }
            .padding(12)
            .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .jammyCard(radius: 24, fill: Color(.jammySurfaceWarm), playful: true)
    }
}

/// 홈의 여행 목록 한 줄.
struct TripRowCard: View {
    let title: String
    let meta: String
    let statusTitle: String
    var statusKind: JammyChip.Kind = .neutral
    var tone: PhotoPlaceholder.Tone = .pink

    var body: some View {
        HStack(spacing: 14) {
            PhotoPlaceholder(tone: tone)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(.bold, size: 16, relativeTo: .headline))
                    .foregroundStyle(Color(.jammyTextPrimary))
                Text(meta)
                    .font(.pretendard(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(.jammyTextSecondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            JammyChip(title: statusTitle, kind: statusKind)
        }
        .padding(14)
        .jammyCard()
    }
}

/// 피드의 공개 일기 카드.
struct FeedCard: View {
    let author: Member?
    let timeText: String
    let text: String
    /// 비밀 일기(타임캡슐)면 사진과 글 대신 가림 표시를 보여준다.
    var isSecret = false
    var photoURL: URL?
    var photoData: Data?
    var tone: PhotoPlaceholder.Tone = .sunny

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let author { JammyAvatar(member: author) } else { JammyAvatar(initial: "?") }
                VStack(alignment: .leading, spacing: 0) {
                    Text(author?.nickname ?? "알 수 없음")
                        .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text(timeText)
                        .font(.pretendard(.medium, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(.jammyTextTertiary))
                }
                if isSecret {
                    Spacer(minLength: 0)
                    JammyChip(title: "비밀 일기", kind: .yellow, systemImage: "lock.fill")
                }
            }
            if isSecret {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.jammyYellowText))
                        .frame(width: 32, height: 32)
                        .background(Color(.jammySurface), in: Circle())
                    Text("타임캡슐에 담긴 비밀 일기예요.\n공개 시간이 되면 함께 볼 수 있어요.")
                        .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyYellowText))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color(.jammySecondarySoft), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                if photoURL != nil || photoData != nil {
                    JammyPhoto(data: photoData, url: photoURL, tone: tone)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Text(text)
                    .font(.pretendard(.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(Color(.jammyTextPrimary))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .jammyCard()
    }
}

/// 타임캡슐 상태 카드. `isOpened` 로 공개 전/후를 구분한다.
struct CapsuleCard: View {
    let title: String
    let subtitle: String
    let isOpened: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOpened ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(isOpened ? .jammyAccentGreen : .jammyTextPrimary))
                .frame(width: 44, height: 44)
                .background(Color(isOpened ? .jammyGreenSoft : .jammySecondary), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(.bold, size: 16, relativeTo: .headline))
                    .foregroundStyle(Color(.jammyTextPrimary))
                Text(subtitle)
                    .font(.pretendard(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(.jammyTextSecondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            JammyChip(title: isOpened ? "열림" : "잠금", kind: isOpened ? .green : .yellow)
        }
        .padding(16)
        .jammyCard(radius: 24, fill: Color(.jammySurfaceWarm), playful: true)
    }
}

/// 비밀 일기(타임캡슐) 카드.
struct SecretEntryCard: View {
    let author: Member?
    let text: String
    var photoURL: URL?
    var photoData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let author { JammyAvatar(member: author) } else { JammyAvatar(initial: "?") }
                Text(author?.nickname ?? "알 수 없음")
                    .font(.pretendard(.semibold, size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Color(.jammyTextPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                JammyChip(title: "비밀 일기", kind: .yellow, systemImage: "lock.fill")
            }
            if photoURL != nil || photoData != nil {
                JammyPhoto(data: photoData, url: photoURL)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Text(text)
                .font(.pretendard(.regular, size: 15, relativeTo: .body))
                .foregroundStyle(Color(.jammyTextPrimary))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .jammyCard()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            FeaturedTripCard(title: "부산 여행", meta: "10.12 – 10.14 · 3명", statusTitle: "여행 중",
                             capsuleTitle: "타임캡슐 잠금 중", capsuleSubtitle: "10.14 오후 8:00 공개", dDay: "D-2")
            TripRowCard(title: "제주 가을 여행", meta: "9.20 – 9.23 · 4명", statusTitle: "열림", statusKind: .green)
            FeedCard(author: Member(nickname: "민지"), timeText: "방금 전", text: "해운대에 도착했다! 날씨가 정말 좋다.")
            CapsuleCard(title: "부산 여행 마지막 밤", subtitle: "10.14 오후 8:00 공개 · D-2", isOpened: false)
            SecretEntryCard(author: Member(nickname: "서준"), text: "돼지국밥 먹고 나서 친구들 표정이 아직도 생각난다.")
        }
        .padding(20)
    }
    .background(Color(.jammyBackground))
}
