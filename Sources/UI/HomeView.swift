//
//  HomeView.swift
//  AppleMusic
//
//  「主页」。
//
//  结构（对照参考图）：
//    左上「主页」大标题 + 右上角圆形头像按钮
//    「最近播放」大卡（封面 + 标题 + 副标题）横滑
//    「开始聆听」横滑大卡
//    「为你推荐」横滑
//
//  各板块可用设置开关隐藏。
//

import SwiftUI

struct HomeView: View {

    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings

    @State private var recentlyPlayed: [Song] = []
    @State private var playlists: [Playlist] = []
    @State private var newSongs: [Song] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var selectedSong: Song?

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {

                        header

                        if isLoading && recentlyPlayed.isEmpty && newSongs.isEmpty {
                            LoadingStateView(text: "正在载入…")
                        } else if recentlyPlayed.isEmpty && newSongs.isEmpty && playlists.isEmpty {
                            VStack(spacing: 12) {
                                EmptyStateView(icon: "wifi.exclamationmark", title: "无法载入",
                                               message: errorText ?? "请检查网络后重试")
                                Button { Task { await load() } } label: {
                                    Text("重试")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 26).padding(.vertical, 11)
                                        .background(Capsule().fill(settings.accent.color))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            .frame(maxWidth: .infinity)
                        } else {

                            // 最近播放
                            if !recentlyPlayed.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("最近播放")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(Array(recentlyPlayed.prefix(8).enumerated()), id: \.element.identityKey) { index, song in
                                                Button {
                                                    Haptics.success()
                                                    player.play(songs: recentlyPlayed, startAt: index)
                                                    showNowPlaying = true
                                                } label: {
                                                    LargeMediaCard(
                                                        title: song.name,
                                                        subtitle: song.artists,
                                                        coverURL: song.coverURL,
                                                        width: 300
                                                    )
                                                }
                                                .buttonStyle(PressableButtonStyle(scale: 0.98))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // 开始聆听
                            if !playlists.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("开始聆听")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(playlists) { item in
                                                NavigationLink {
                                                    PlaylistDetailView(playlist: item, showNowPlaying: $showNowPlaying)
                                                        .environmentObject(player)
                                                        .environmentObject(favorites)
                                                } label: {
                                                    LargeMediaCard(
                                                        title: item.name,
                                                        subtitle: item.creatorName.isEmpty ? "精选歌单" : item.creatorName,
                                                        coverURL: item.coverURL,
                                                        width: 220
                                                    )
                                                }
                                                .buttonStyle(PressableButtonStyle(scale: 0.98))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // 为你推荐
                            if !newSongs.isEmpty, settings.showHomeNewAlbums {
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text("新歌精选")
                                            .font(.system(size: 22, weight: .bold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)

                                    ForEach(Array(newSongs.prefix(12).enumerated()), id: \.element.identityKey) { index, song in
                                        SongRow(
                                            song: song,
                                            isCurrent: player.currentSong?.identityKey == song.identityKey,
                                            isPlaying: player.isPlaying,
                                            onTap: {
                                                player.play(songs: newSongs, startAt: index)
                                                showNowPlaying = true
                                            },
                                            onMore: settings.showSongRowMore ? { selectedSong = song } : nil
                                        )
                                        if index < min(11, newSongs.count - 1) { InsetDivider() }
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
        .task { if recentlyPlayed.isEmpty && newSongs.isEmpty { await load() } }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .center) {
            Text("主页")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)

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
        errorText = nil

        async let newTask = NetEaseAPI.shared.newSongs(limit: 20)
        async let listTask = NetEaseAPI.shared.personalizedPlaylists(limit: 10)

        let songs = (try? await newTask) ?? []
        let lists = (try? await listTask) ?? []

        var recent: [Song] = []
        if let topLists = try? await NetEaseAPI.shared.topLists(), let first = topLists.first {
            recent = (try? await NetEaseAPI.shared.playlistTracks(id: first.id)) ?? []
        }
        if recent.isEmpty { recent = songs }

        await MainActor.run {
            newSongs = songs
            playlists = lists
            recentlyPlayed = Array(recent.prefix(20))
            if songs.isEmpty && lists.isEmpty { errorText = "接口暂时不可用" }
            isLoading = false
        }
    }
}

// MARK: - 圆形头像按钮

struct AvatarButton: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showTip = false

    var body: some View {
        Button {
            Haptics.tap()
            showTip = true
        } label: {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [settings.accent.color, settings.accent.color.opacity(0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 34, height: 34)
                .overlay {
                    Text("K")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.92))
        .alert("账号", isPresented: $showTip) {
            Button("好", role: .cancel) {}
        } message: {
            Text("在「我的 → 设置 → 账号与平台」里登录各平台账号。")
        }
    }
}

// MARK: - 大媒体卡（最近播放 / 开始聆听）

struct LargeMediaCard: View {
    let title: String
    let subtitle: String
    let coverURL: URL?
    var width: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverArtView(url: coverURL, size: width, cornerRadius: 10)
                .frame(width: width, height: width * 0.62)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(width: width, alignment: .leading)
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
