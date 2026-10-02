import SwiftUI

/// 방 생성 직후 보여주는 초대 코드 발급 화면.
struct InviteCodeView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: InviteCodeViewModel

    init(viewModel: InviteCodeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                VStack(spacing: 12) {
                    Text(error.errorDescription ?? "불러오지 못했어요.")
                        .font(.pretendard(.medium, size: 14))
                        .foregroundStyle(Color(.jammyTextSecondary))
                    JammyButton(title: "다시 시도", kind: .soft) { Task { await viewModel.load() } }
                        .frame(width: 160)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let room):
                loaded(room)
            }
        }
        .task { await viewModel.load() }
        .jammyScreenStyle()
        .navigationBarBackButtonHidden()
    }

    private func loaded(_ room: TripRoom) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(.jammyTextPrimary))
                        .frame(width: 56, height: 56)
                        .background(Color(.jammySecondary), in: Circle())
                    Text("방이 만들어졌어요!")
                        .font(.pretendard(.extrabold, size: 26, relativeTo: .title))
                        .foregroundStyle(Color(.jammyTextPrimary))
                    Text("친구들에게 초대 코드를 공유해 주세요.")
                        .font(.pretendard(.regular, size: 15, relativeTo: .body))
                        .foregroundStyle(Color(.jammyTextSecondary))
                }
                .padding(.top, 16)

                codeJar(room)

                HStack(spacing: 12) {
                    JammyButton(title: viewModel.didCopy ? "복사했어요" : "코드 복사", kind: .soft, systemImage: viewModel.didCopy ? "checkmark" : "doc.on.doc") {
                        Task { await viewModel.copyCode(room) }
                    }
                    ShareLink(item: viewModel.shareText(for: room)) {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .semibold))
                            Text("링크 공유")
                        }
                        .font(.pretendard(.semibold, size: 15))
                        .foregroundStyle(Color(.jammyTextPrimary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(.jammySecondary), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                joinedCard(room)
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            JammyButton(title: "방으로 들어가기") { router.enterRoom(room.id) }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.jammyBackground))
        }
    }

    private func codeJar(_ room: TripRoom) -> some View {
        VStack(spacing: 12) {
            JamJarView(width: 220) {
                VStack(spacing: 4) {
                    Text("초대 코드")
                        .font(.pretendard(.medium, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(.jammyTextTertiary))
                    Text(room.inviteCode)
                        .font(.pretendard(.extrabold, size: 26, relativeTo: .title))
                        .foregroundStyle(Color(.jammyPrimary))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.jammySurfaceWarm), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.jammyBorder), lineWidth: 1)
                }
            }
            Text(viewModel.metaText(for: room))
                .font(.pretendard(.regular, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color(.jammyTextSecondary))
            if let capsuleText = viewModel.capsuleText(for: room) {
                JammyChip(title: capsuleText, kind: .yellow, systemImage: "lock.fill")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func joinedCard(_ room: TripRoom) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("참여한 친구")
                    .font(.pretendard(.bold, size: 15, relativeTo: .headline))
                    .foregroundStyle(Color(.jammyTextPrimary))
                Spacer()
                Text("\(room.members.count) / \(room.maxMembers)")
                    .font(.pretendard(.semibold, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color(.jammyPrimary))
            }
            HStack(spacing: 12) {
                ForEach(room.members) { member in
                    JammyAvatar(member: member, size: .medium)
                }
                ForEach(0..<max(0, room.maxMembers - room.members.count), id: \.self) { _ in
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.jammyTextTertiary))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle().strokeBorder(Color(.jammyBorder), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        }
                }
                Spacer(minLength: 0)
                JammyChip(title: "방장", kind: .yellow)
            }
        }
        .padding(16)
        .background(Color(.jammySurface), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.jammyBorder), lineWidth: 1)
        }
    }
}

#Preview {
    let container = AppContainer.mock()
    NavigationStack {
        InviteCodeView(viewModel: container.makeInviteCodeViewModel(roomID: UUID()))
    }
    .environment(AppRouter())
}
