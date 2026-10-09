//
//  RadioView.swift
//  AppleMusic
//
//  「广播」。
//
//  结构（对照参考图）：
//    左上「广播」大标题 + 右上角圆形头像
//    「推荐单集」大字标题 + 大卡（左下角两个文字标签）
//    「新近内容 ›」横滑列表
//

import SwiftUI

struct RadioView: View {

    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings

    @State private var shows: [Playlist] = []
    @State private var episodes: [Playlist] = []
    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {

                        header

                        if isLoading && shows.isEmpty {
                            LoadingStateView(text: "正在载入…")
                        } else if shows.isEmpty {
                            VStack(spacing: 12) {
                                EmptyStateView(icon: "dot.radiowaves.left.and.right",
                                               title: "暂无内容", message: errorText ?? "稍后再试试")
                                Button { Task { await load() } } label: {
                                    Text("重新载入")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 26).padding(.vertical, 11)
                                        .background(Capsule().fill(settings.accent.color))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            .frame(maxWidth: .infinity)
                        } else {

                            // 推荐单集
                            if let first = shows.first {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("推荐单集")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)

                                    NavigationLink {
                                        PlaylistDetailView(playlist: first, showNowPlaying: $showNowPlaying)
                                            .environmentObject(player)
                                            .environmentObject(favorites)
                                    } label: {
                                        RadioBigCard(playlist: first)
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.98))
                                    .padding(.horizontal, 16)
                                }
                            }

                            // 新近内容
                            if !episodes.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("新近内容")
                                            .font(.system(size: 22, weight: .bold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(alignment: .top, spacing: 14) {
                                            ForEach(episodes) { item in
                                                NavigationLink {
                                                    PlaylistDetailView(playlist: item, showNowPlaying: $showNowPlaying)
                                                        .environmentObject(player)
                                                        .environmentObject(favorites)
                                                } label: {
                                                    RadioEpisodeCard(playlist: item)
                                                }
                                                .buttonStyle(PressableButtonStyle(scale: 0.97))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 170)
                    }
                    .padding(.top, 6)
                }
                .compatScrollIndicatorsHidden()
                .refreshable { await load() }
            }
            .navigationBarHidden(true)
        }
        .task { if shows.isEmpty { await load() } }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("广播")
                .font(.system(size: 34, weight: .bold))

            Spacer()

            if settings.showTopLeftAvatar {
                AvatarButton()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func load() async {
        isLoading = true
        let list = (try? await NetEaseAPI.shared.personalizedPlaylists(limit: 20)) ?? []
        await MainActor.run {
            shows = list
            episodes = Array(list.dropFirst().prefix(10))
            if list.isEmpty { errorText = "接口暂时不可用" }
            isLoading = false
        }
    }
}

// MARK: - 推荐单集大卡

struct RadioBigCard: View {
    let playlist: Playlist

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CoverArtView(url: playlist.coverURL, size: 360, cornerRadius: 12)
                .frame(maxWidth: .infinity)
                .aspectRatio(1.35, contentMode: .fit)

            LinearGradient(
                colors: [.clear, .black.opacity(0.60)],
                startPoint: .center, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("精选")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(0.22)))
                    Text("音乐")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(0.22)))
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - 单集卡

struct RadioEpisodeCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(url: playlist.coverURL, size: 220, cornerRadius: 10)
                .frame(width: 220, height: 220)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 220, alignment: .leading)

                Text(playlist.creatorName.isEmpty ? "电台" : playlist.creatorName)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 220, alignment: .leading)
            }
        }
        .frame(width: 220)
    }
}
