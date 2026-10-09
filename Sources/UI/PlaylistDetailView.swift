//
//  PlaylistDetailView.swift
//  AppleMusic
//
//  歌单详情：大封面 + 播放全部 + 歌曲列表。
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var songs: [Song] = []
    @State private var isLoading = true
    @State private var errorText: String?
    @State private var selectedSong: Song?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom, spacing: 14) {
                    CoverArtView(url: playlist.coverURL, size: 110, cornerRadius: 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(playlist.name)
                            .font(.system(size: 20, weight: .bold))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)

                        if !playlist.creatorName.isEmpty {
                            Text(playlist.creatorName)
                                .font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                        }

                        Button {
                            guard !songs.isEmpty else { return }
                            Haptics.success()
                            player.play(songs: songs, startAt: 0)
                            showNowPlaying = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill").font(.system(size: 13, weight: .semibold))
                                Text("播放").font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20).padding(.vertical, 8)
                            .background(Capsule().fill(Color.accentColor))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(songs.isEmpty)
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Divider().padding(.leading, 20)

                if isLoading && songs.isEmpty {
                    LoadingStateView(text: "正在载入歌曲…")
                } else if songs.isEmpty {
                    EmptyStateView(icon: "music.note.list", title: "没有歌曲",
                                   message: errorText ?? "这个歌单暂时无法载入")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(songs.enumerated()), id: \.element.identityKey) { index, song in
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
                            if index < songs.count - 1 { InsetDivider() }
                        }
                    }
                }

                Spacer(minLength: 160)
            }
        }
        .compatScrollIndicatorsHidden()
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    private func load() async {
        isLoading = true
        errorText = nil

        var result: [Song] = []
        switch playlist.source {
        case .netease: result = (try? await NetEaseAPI.shared.playlistTracks(id: playlist.id)) ?? []
        case .qq:      result = (try? await QQMusicAPI.shared.playlistSongs(listID: playlist.id)) ?? []
        case .kugou:   result = (try? await KugouMusicAPI.shared.playlistSongs(listID: playlist.id)) ?? []
        }

        await MainActor.run {
            songs = result
            if result.isEmpty { errorText = "歌单载入失败" }
            isLoading = false
        }
    }
}
