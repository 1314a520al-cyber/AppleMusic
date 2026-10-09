//
//  BrowseView.swift
//  AppleMusic
//
//  「浏览」。
//
//  结构（对照参考图）：
//    顶部居中「浏览」标题 + 右上角圆形头像
//    「歌单已更新」大卡（封面 + 描述）
//    「新歌精选 ›」列表（封面 + 歌名 + 歌手 + 三点）
//    「本周新发行 ›」「新近发布 ›」横滑专辑卡
//

import SwiftUI

struct BrowseView: View {

    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings

    @State private var featured: Playlist?
    @State private var newSongs: [Song] = []
    @State private var albums: [Playlist] = []
    @State private var recent: [Playlist] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var selectedSong: Song?

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        header

                        if isLoading && newSongs.isEmpty {
                            LoadingStateView(text: "正在载入…")
                        } else if newSongs.isEmpty {
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

                            // 歌单已更新
                            if let featured {
                                NavigationLink {
                                    PlaylistDetailView(playlist: featured, showNowPlaying: $showNowPlaying)
                                        .environmentObject(player)
                                        .environmentObject(favorites)
                                } label: {
                                    FeaturedCard(playlist: featured)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.98))
                                .padding(.horizontal, 16)
                            }

                            // 新歌精选
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
                                .padding(.bottom, 6)

                                ForEach(Array(newSongs.prefix(8).enumerated()), id: \.element.identityKey) { index, song in
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
                                    if index < min(7, newSongs.count - 1) { InsetDivider() }
                                }
                            }

                            // 本周新发行
                            if !albums.isEmpty {
                                horizontalSection(title: "本周新发行", items: albums)
                            }

                            // 新近发布
                            if !recent.isEmpty {
                                horizontalSection(title: "新近发布", items: recent)
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
        .task { if newSongs.isEmpty { await load() } }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    private var header: some View {
        ZStack {
            Text("浏览")
                .font(.system(size: 20, weight: .semibold))

            HStack {
                Spacer()
                if settings.showTopLeftAvatar {
                    AvatarButton()
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func horizontalSection(title: String, items: [Playlist]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(items) { item in
                        NavigationLink {
                            PlaylistDetailView(playlist: item, showNowPlaying: $showNowPlaying)
                                .environmentObject(player)
                                .environmentObject(favorites)
                        } label: {
                            AlbumCard(playlist: item)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.97))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func load() async {
        isLoading = true
        errorText = nil

        async let newTask = NetEaseAPI.shared.newSongs(limit: 20)
        async let listTask = NetEaseAPI.shared.personalizedPlaylists(limit: 16)

        let songs = (try? await newTask) ?? []
        let lists = (try? await listTask) ?? []

        await MainActor.run {
            newSongs = songs
            featured = lists.first
            albums = Array(lists.prefix(8))
            recent = Array(lists.dropFirst(8).prefix(8))
            if songs.isEmpty && lists.isEmpty { errorText = "接口暂时不可用" }
            isLoading = false
        }
    }
}

// MARK: - 歌单已更新大卡

struct FeaturedCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                CoverArtView(url: playlist.coverURL, size: 360, cornerRadius: 0)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.5, contentMode: .fit)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)],
                    startPoint: .center, endPoint: .bottom
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("歌单已更新")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(playlist.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !playlist.creatorName.isEmpty {
                    Text(playlist.creatorName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - 专辑卡

struct AlbumCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(url: playlist.coverURL, size: 160, cornerRadius: 8)
                .overlay(alignment: .topTrailing) {
                    // 参考图里的 "E" 标识（Explicit）
                    Text("E")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.55)))
                        .padding(6)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .leading)

                Text(playlist.creatorName.isEmpty ? "合辑" : playlist.creatorName)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .leading)
            }
        }
        .frame(width: 160)
    }
}
