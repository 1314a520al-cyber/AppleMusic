//
//  HomeView.swift
//  AppleMusic
//
//  「主页」：大标题 + 热门歌单横滑 + 推荐歌曲 + 新歌。
//

import SwiftUI

struct HomeView: View {
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var recommended: [Song] = []
    @State private var newSongs: [Song] = []
    @State private var hotPlaylists: [Playlist] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var selectedSong: Song?

    var body: some View {
        CompatNavigationStack {
            ZStack {
                AmbienceBackdrop(tint: .accentColor)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("主页")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if isLoading && recommended.isEmpty && newSongs.isEmpty {
                            LoadingStateView(text: "正在获取推荐…")
                        } else if recommended.isEmpty && newSongs.isEmpty {
                            VStack(spacing: 12) {
                                EmptyStateView(icon: "wifi.exclamationmark", title: "无法载入推荐",
                                               message: errorText ?? "请检查网络后重试")
                                Button { Task { await load() } } label: {
                                    Text("重试")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 26).padding(.vertical, 11)
                                        .background(Capsule().fill(Color.accentColor))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            if !hotPlaylists.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    SectionTitle(text: "热门歌单").padding(.horizontal, 20)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(hotPlaylists) { item in
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
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }

                            if !newSongs.isEmpty {
                                songSection(title: "新歌速递", songs: newSongs)
                            }

                            if !recommended.isEmpty {
                                songSection(title: "为你推荐", songs: recommended)
                            }
                        }

                        Spacer(minLength: 150)
                    }
                }
                .compatScrollIndicatorsHidden()
                .refreshable { await load() }
            }
            .navigationBarHidden(true)
        }
        .task { if recommended.isEmpty && newSongs.isEmpty { await load() } }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    private func songSection(title: String, songs: [Song]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(text: title)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            ForEach(Array(songs.prefix(15).enumerated()), id: \.element.identityKey) { index, song in
                SongRow(
                    song: song,
                    isCurrent: player.currentSong?.identityKey == song.identityKey,
                    isPlaying: player.isPlaying,
                    onTap: {
                        player.play(songs: songs, startAt: index)
                        showNowPlaying = true
                    },
                    onMore: { selectedSong = song }
                )
                if index < min(14, songs.count - 1) { InsetDivider() }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorText = nil

        async let newTask = NetEaseAPI.shared.newSongs(limit: 20)
        async let recTask = NetEaseAPI.shared.personalizedPlaylists(limit: 12)

        let newList = (try? await newTask) ?? []
        let playlists = (try? await recTask) ?? []

        // 「为你推荐」用网易云热歌榜作为推荐内容
        var recommend: [Song] = []
        if let lists = try? await NetEaseAPI.shared.topLists(), let first = lists.first {
            recommend = (try? await NetEaseAPI.shared.playlistTracks(id: first.id)) ?? []
        }

        await MainActor.run {
            if newList.isEmpty && playlists.isEmpty {
                errorText = "网易云接口暂时不可用，请稍后重试"
            }
            newSongs = newList
            hotPlaylists = playlists
            recommended = Array(recommend.prefix(40))
            isLoading = false
        }
    }
}

// MARK: - 歌单卡片

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(url: playlist.coverURL, size: 150, cornerRadius: 8)

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
