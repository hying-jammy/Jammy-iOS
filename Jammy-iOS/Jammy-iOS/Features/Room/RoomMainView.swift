import SwiftUI

/// 여행 방 메인: 피드 / 기록 탭 + 타임캡슐 상태 카드 + 기록 작성 버튼.
struct RoomMainView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RoomMainViewModel
    @State private var isWriting = false

    init(viewModel: RoomMainViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    topBar
                    titleBlock
                    RoomTabs(selection: $viewModel.tab)
                    content
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 96)
            }
            .refreshable { await viewModel.load() }

            JammyFAB(accessibilityLabel: "오늘의 순간 담기") { isWriting = true }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
        }
        .onAppear { Task { await viewModel.load() } }
        .sheet(isPresented: $isWriting) {
            WriteDiaryView(viewModel: container.makeWriteDiaryViewModel(roomID: viewModel.roomID)) {
                Task { await viewModel.load() }
            }
            .presentationCornerRadius(28)
        }
        .jammyScreenStyle()
    }

    // MARK: - Sections

    private var topBar: some View {
        JammyTopBar(onBack: { dismiss() }) {
            if let room = viewModel.room {
                Button {
                    router.push(.inviteCode(roomID: room.id))
                } label: {
                    JammyChip(title: "초대 코드 \(room.inviteCode)", kind: .yellow, systemImage: "key")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("초대 코드 보기")
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.room?.title ?? " ")
                .font(.pretendard(.extrabold, size: 28, relativeTo: .title))
                .foregroundStyle(Color(.jammyTextPrimary))
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(viewModel.metaText)
                Image(systemName: "person.2")
                    .padding(.leading, 4)
                Text(viewModel.membersText)
                    .lineLimit(1)
            }
            .font(.pretendard(.medium, size: 14, relativeTo: .subheadline))
            .foregroundStyle(Color(.jammyTextSecondary))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
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
            VStack(alignment: .leading, spacing: 16) {
                if let capsule = viewModel.capsuleSummary, let room = viewModel.room {
                    Button {
                        router.push(.capsule(roomID: room.id))
                    } label: {
                        CapsuleCard(title: capsule.title, subtitle: capsule.subtitle, isOpened: capsule.isOpened)
                    }
                    .buttonStyle(.plain)
                }
                switch viewModel.tab {
                case .feed: feed
                case .records: records
                }
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "친구들의 순간", trailing: "최신순")
            if viewModel.feedItems.isEmpty {
                emptyView(title: "아직 올라온 순간이 없어요", message: "첫 번째 순간을 담아볼까요?")
            } else {
                ForEach(viewModel.feedItems) { item in
                    FeedCard(author: item.author, timeText: item.timeText, text: item.text, photoData: item.photoData)
                }
            }
        }
    }

    private var records: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.timelineSections.isEmpty {
                emptyView(title: "아직 기록이 없어요", message: "여행이 시작되면 날짜별로 모아 보여드려요.")
            } else {
                ForEach(viewModel.timelineSections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text(section.title)
                                .font(.pretendard(.bold, size: 16, relativeTo: .headline))
                                .foregroundStyle(Color(.jammyTextPrimary))
                            Text(section.countText)
                                .font(.pretendard(.medium, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color(.jammyTextTertiary))
                        }
                        ForEach(section.items) { item in
                            RecordRow(item: item)
                        }
                    }
                }
            }
        }
    }

    private func emptyView(title: String, message: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.pretendard(.bold, size: 16, relativeTo: .headline))
                .foregroundStyle(Color(.jammyTextPrimary))
            Text(message)
                .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color(.jammyTextSecondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

/// 기록 탭의 타임라인 한 줄.
private struct RecordRow: View {
    let item: RoomMainViewModel.TimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(item.isCapsule ? .jammySecondary : .jammyPrimary))
                .frame(width: 10, height: 10)
                .padding(.top, 18)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.authorName)
                            .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(Color(.jammyTextPrimary))
                        JammyChip(title: item.isCapsule ? "타임캡슐" : "공개", kind: item.isCapsule ? .yellow : .primary)
                    }
                    Text(item.text)
                        .font(.pretendard(.regular, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color(.jammyTextSecondary))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let data = item.photoData {
                    JammyPhoto(data: data)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(14)
            .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(.jammyBorder), lineWidth: 1)
            }
        }
    }
}

#Preview {
    let container = AppContainer.mock()
    NavigationStack {
        RoomMainView(viewModel: container.makeRoomMainViewModel(roomID: UUID()))
    }
    .environment(container)
    .environment(AppRouter())
}
