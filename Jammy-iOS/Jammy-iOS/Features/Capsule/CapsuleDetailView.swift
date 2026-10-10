import SwiftUI

/// 타임캡슐 상세. 공개 전(잠금·카운트다운)과 공개 후(그룹원 기록) 두 상태.
struct CapsuleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CapsuleDetailViewModel

    init(viewModel: CapsuleDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                VStack {
                    JammyTopBar(title: "타임캡슐", onBack: { dismiss() }).padding(.horizontal, 20)
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .failed(let error):
                VStack(spacing: 12) {
                    JammyTopBar(title: "타임캡슐", onBack: { dismiss() }).padding(.horizontal, 20)
                    Spacer()
                    Text(error.errorDescription ?? "불러오지 못했어요.")
                        .font(.pretendard(.medium, size: 14))
                        .foregroundStyle(Color(.jammyTextSecondary))
                    JammyButton(title: "다시 시도", kind: .soft) { Task { await viewModel.load() } }
                        .frame(width: 160)
                    Spacer()
                }
            case .loaded:
                if viewModel.isOpened {
                    openedView
                } else {
                    lockedView
                }
            }
        }
        .task { await viewModel.load() }
        // 1초마다 현재 시각을 갱신해 카운트다운과 공개 전환을 반영한다.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await viewModel.tick()
            }
        }
        .jammyScreenStyle()
    }

    // MARK: - 공개 전

    private var lockedView: some View {
        ScrollView {
            VStack(spacing: 18) {
                JammyTopBar(title: "타임캡슐", onBack: { dismiss() })

                VStack(spacing: 10) {
                    JamJarView(width: 120) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(.jammyPrimary))
                            .frame(width: 40, height: 40)
                            .background(Color(.jammySurface), in: Circle())
                            .overlay(Circle().strokeBorder(Color(.jammyBorder), lineWidth: 1))
                    }
                    Text(viewModel.title)
                        .font(.pretendard(.extrabold, size: 24, relativeTo: .title2))
                        .foregroundStyle(Color(.jammyTextPrimary))
                        .multilineTextAlignment(.center)
                    Text("모두의 비밀 기록이 잠겨 있어요")
                        .font(.pretendard(.regular, size: 15, relativeTo: .body))
                        .foregroundStyle(Color(.jammyTextSecondary))
                }

                if let countdown = viewModel.countdown {
                    HStack(spacing: 10) {
                        countBox(value: countdown.days, unit: "일")
                        countBox(value: countdown.hours, unit: "시간")
                        countBox(value: countdown.minutes, unit: "분")
                    }
                }

                Label(viewModel.openAtText, systemImage: "calendar")
                    .font(.pretendard(.medium, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color(.jammyTextSecondary))

                memberCard
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            JammyButton(title: "아직 열 수 없어요") {}
                .disabled(true)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.jammyBackground))
        }
    }

    private func countBox(value: Int, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.pretendard(.extrabold, size: 28, relativeTo: .title))
                .foregroundStyle(Color(.jammyPrimary))
                .monospacedDigit()
            Text(unit)
                .font(.pretendard(.medium, size: 12, relativeTo: .caption))
                .foregroundStyle(Color(.jammyTextTertiary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.jammyBorder), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var memberCard: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.memberRows) { row in
                HStack(spacing: 10) {
                    JammyAvatar(member: Member(nickname: row.nickname))
                    Text(row.nickname)
                        .font(.pretendard(.semibold, size: 15, relativeTo: .headline))
                        .foregroundStyle(Color(.jammyTextPrimary))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    JammyChip(title: row.hasSubmitted ? "기록 완료" : "작성 중", kind: row.hasSubmitted ? .green : .neutral)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.jammyBorder), lineWidth: 1)
        }
    }

    // MARK: - 공개 후

    private var openedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                JammyTopBar(title: "타임캡슐", onBack: { dismiss() }) {
                    JammyChip(title: "함께 열었어요", kind: .green, systemImage: "checkmark")
                }

                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(.jammyYellowText))
                        .frame(width: 44, height: 44)
                        .background(Color(.jammySurface), in: Circle())
                    Text("서로의 기억이 열렸어요")
                        .font(.pretendard(.extrabold, size: 20, relativeTo: .title3))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text(viewModel.openedSubtitle)
                        .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(.jammyYellowText))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.jammySecondarySoft), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color(.jammyPrimary).opacity(0.12), radius: 10, y: 8)

                SectionHeader(title: "함께 연 기록", trailing: "\(viewModel.entryItems.count)개")

                if viewModel.entryItems.isEmpty {
                    Text("담긴 비밀 일기가 없어요.")
                        .font(.pretendard(.regular, size: 14))
                        .foregroundStyle(Color(.jammyTextSecondary))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(viewModel.entryItems) { item in
                        SecretEntryCard(author: item.author, text: item.text, photoURL: item.photoURL, photoData: item.photoData)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    let container = AppContainer.mock()
    NavigationStack {
        CapsuleDetailView(viewModel: container.makeCapsuleDetailViewModel(roomID: 1))
    }
}
