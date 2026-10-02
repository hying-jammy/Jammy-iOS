import SwiftUI

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                greeting
                actions
                content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .refreshable { await viewModel.load() }
        // 다른 화면에서 돌아올 때마다 목록을 조용히 갱신한다.
        .onAppear { Task { await viewModel.load() } }
        .jammyScreenStyle()
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Text("J")
                    .font(.pretendard(.extrabold, size: 13))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color(.jammyPrimary), in: Circle())
                Text("Jammy")
                    .font(.pretendard(.extrabold, size: 22, relativeTo: .title2))
                    .foregroundStyle(Color(.jammyPrimary))
            }
            Spacer()
            Menu {
                Button("로그아웃", role: .destructive) {
                    Task {
                        await viewModel.logout()
                        router.didSignOut()
                    }
                }
            } label: {
                JammyAvatar(initial: String(viewModel.nickname.prefix(1)), tone: Color(.jammySecondarySoft), size: .medium)
            }
            .accessibilityLabel("내 계정")
        }
        .frame(height: 48)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.nickname.isEmpty ? "안녕하세요!" : "안녕, \(viewModel.nickname)!")
                .font(.pretendard(.extrabold, size: 28, relativeTo: .title))
                .foregroundStyle(Color(.jammyTextPrimary))
            Text("이번엔 어떤 여행을 담아볼까요?")
                .font(.pretendard(.regular, size: 16, relativeTo: .body))
                .foregroundStyle(Color(.jammyTextSecondary))
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            JammyButton(title: "여행 방 만들기") { router.push(.createRoom) }
            JammyButton(title: "초대 코드 입력", kind: .soft) { router.push(.joinRoom) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        case .failed(let error):
            VStack(spacing: 12) {
                Text(error.errorDescription ?? "불러오지 못했어요.")
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color(.jammyTextSecondary))
                JammyButton(title: "다시 시도", kind: .soft) { Task { await viewModel.load() } }
                    .frame(width: 160)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        case .loaded:
            if viewModel.isEmpty {
                emptyState
            } else {
                roomList
            }
        }
    }

    private var roomList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "참여 중인 여행", trailing: "\(viewModel.totalCount)개")
                .padding(.top, 8)

            if let featured = viewModel.featured {
                Button {
                    router.push(.room(roomID: featured.id))
                } label: {
                    FeaturedTripCard(
                        title: featured.title,
                        meta: featured.meta,
                        statusTitle: featured.statusTitle,
                        statusKind: featured.statusKind,
                        capsuleTitle: featured.capsuleTitle,
                        capsuleSubtitle: featured.capsuleSubtitle,
                        dDay: featured.dDay
                    )
                }
                .buttonStyle(.plain)
            }

            ForEach(viewModel.rows) { row in
                Button {
                    router.push(.room(roomID: row.id))
                } label: {
                    TripRowCard(
                        title: row.title,
                        meta: row.meta,
                        statusTitle: row.statusTitle,
                        statusKind: row.statusKind,
                        tone: row.tone
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            JamJarView(width: 110)
            Text("아직 담은 여행이 없어요")
                .font(.pretendard(.bold, size: 18, relativeTo: .headline))
                .foregroundStyle(Color(.jammyTextPrimary))
            Text("방을 만들거나 친구에게 받은 초대 코드로\n첫 번째 잼을 담아보세요.")
                .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color(.jammyTextSecondary))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: AppContainer.mock().makeHomeViewModel())
    }
    .environment(AppRouter())
}
