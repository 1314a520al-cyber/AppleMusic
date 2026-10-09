//
//  HomeView.swift
//  AppleMusic
//
//  「主页」：顶部栏 + 每日推荐 + 私人漫游大卡 + 排行榜横滑 + 新歌上架。
//  每个板块都可用设置开关隐藏。
//

import SwiftUI

struct HomeView: View {

    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings

    @State private var dailySongs: [Song] = []
    @State private var rankPlaylists: [Playlist] = []
    @State private var newSongs: [Song] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var selectedSong: Song?

    var body: some View {
        CompatNavigationStack {
            ZStack {
                BackdropLayer()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        TopBar(title: "主页", showNowPlaying: $showNowPlaying)

                        if isLoading && dailySongs.isEmpty && newSongs.isEmpty {
                            LoadingStateView(text: "正在载入…")
                        } else if dailySongs.isEmpty && newSongs.isEmpty {
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

                            if settings.showHomeRecommend, !dailySongs.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("每日推荐")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, 16)

                                    Button {
                                        Haptics.success()
                                        player.play(songs: dailySongs, startAt: 0)
                                        showNowPlaying = true
                                    } label: {
                                        BigEntryCard(
                                            title: "每日推荐",
                                            subtitle: "根据你的口味生成 · \(dailySongs.count) 首",
                                            coverURL: dailySongs.first?.coverURL,
                                            accent: settings.accent.color
                                        )
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.98))
                                    .padding(.horizontal, 16)
                                }
                            }

                            if settings.showHomeRoam, !newSongs.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("私人漫游")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, 16)

                                    Button {
                                        Haptics.success()
                                        player.setPlayMode(.shuffle)
                                        player.play(songs: newSongs, startAt: Int.random(in: 0..<max(1, newSongs.count)))
                                        showNowPlaying = true
                                    } label: {
                                        RoamCard()
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.98))
                                    .padding(.horizontal, 16)
                                }
                            }

                            if settings.showHomeRanking, !rankPlaylists.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("排行榜")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(rankPlaylists) { item in
                                                NavigationLink {
                                                    PlaylistDetailView(playlist: item, showNowPlaying: $showNowPlaying)
                                                        .environmentObject(player)
                                                        .environmentObject(favorites)
                                                } label: {
                                                    PlaylistCard(playlist: item)
                                                }
                                                .buttonStyle(PressableButtonStyle(scale: 0.97))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            if settings.showHomeNewAlbums, !newSongs.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("新歌上架")
                                        .font(.system(size: 22, weight: .bold))
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

                        Spacer(minLength: 160)
                    }
                }
                .compatScrollIndicatorsHidden()
                .refreshable { await load() }
            }
            .navigationBarHidden(true)
        }
        .task { if dailySongs.isEmpty && newSongs.isEmpty { await load() } }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    private func load() async {
        isLoading = true
        errorText = nil

        async let newTask = NetEaseAPI.shared.newSongs(limit: 20)
        async let listTask = NetEaseAPI.shared.personalizedPlaylists(limit: 10)

        let songs = (try? await newTask) ?? []
        let lists = (try? await listTask) ?? []

        var daily: [Song] = []
        if let topLists = try? await NetEaseAPI.shared.topLists(), let first = topLists.first {
            daily = (try? await NetEaseAPI.shared.playlistTracks(id: first.id)) ?? []
        }
        if daily.isEmpty { daily = songs }

        await MainActor.run {
            newSongs = songs
            rankPlaylists = lists
            dailySongs = Array(daily.prefix(60))
            if songs.isEmpty && lists.isEmpty { errorText = "接口暂时不可用" }
            isLoading = false
        }
    }
}

// MARK: - 大卡入口

struct BigEntryCard: View {
    let title: String
    let subtitle: String
    let coverURL: URL?
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            CoverArtView(url: coverURL, size: 64, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(accent)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        }
    }
}

/// 私人漫游：蓝色渐变大卡
struct RoamCard: View {
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.42, blue: 0.92),
                    Color(red: 0.30, green: 0.24, blue: 0.82)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("私人漫游")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("为你随机播放，发现更多好音乐")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "infinity")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - 歌单卡片

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(url: playlist.coverURL, size: 150, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 150, alignment: .leading)

                if playlist.trackCount > 0 {
                    Text("\(playlist.trackCount) 首")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                } else if !playlist.creatorName.isEmpty {
                    Text(playlist.creatorName)
                        .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
        .frame(width: 150)
    }
}
