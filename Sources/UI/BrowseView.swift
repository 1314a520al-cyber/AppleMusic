//
//  BrowseView.swift
//  AppleMusic
//
//  「浏览」页：歌单已更新大卡 + 新歌精选列表。
//  结构与参考图一致，各板块可用设置开关隐藏。
//

import SwiftUI

struct BrowseView: View {

    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var platformStore = PlatformPreferenceStore.shared

    @State private var featured: Playlist?
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

                        TopBar(title: "浏览", showNowPlaying: $showNowPlaying)

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

                            // 大卡片：歌单已更新
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

                            // 新歌精选列表
                            if settings.showHomeNewAlbums {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("新歌精选")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)

                                    ForEach(Array(newSongs.prefix(20).enumerated()), id: \.element.identityKey) { index, song in
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
                                        if index < min(19, newSongs.count - 1) { InsetDivider() }
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
        .task { if newSongs.isEmpty { await load() } }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    private func load() async {
        isLoading = true
        errorText = nil

        async let newTask = NetEaseAPI.shared.newSongs(limit: 25)
        async let listTask = NetEaseAPI.shared.personalizedPlaylists(limit: 8)

        let songs = (try? await newTask) ?? []
        let lists = (try? await listTask) ?? []

        await MainActor.run {
            newSongs = songs
            featured = lists.first
            if songs.isEmpty { errorText = "接口暂时不可用" }
            isLoading = false
        }
    }
}

// MARK: - 大卡片

struct FeaturedCard: View {
    let playlist: Playlist

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CoverArtView(url: playlist.coverURL, size: 340, cornerRadius: 12)
                .frame(maxWidth: .infinity)
                .aspectRatio(1.45, contentMode: .fit)

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("歌单已更新")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(playlist.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
