//
//  LibraryView.swift
//  AppleMusic
//
//  「资料库」：收藏、歌单、下载、历史。
//

import SwiftUI

struct LibraryView: View {
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var playlists: PlaylistStore
    @EnvironmentObject private var downloads: DownloadStore
    @ObservedObject private var history = PlayHistoryStore.shared

    @State private var showNewPlaylist = false
    @State private var newPlaylistName = ""

    var body: some View {
        CompatNavigationStack {
            ZStack {
                AmbienceBackdrop(tint: .pink)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("资料库")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        VStack(spacing: 0) {
                            NavigationLink {
                                FavoritesView(showNowPlaying: $showNowPlaying)
                                    .environmentObject(player).environmentObject(favorites)
                            } label: {
                                categoryRow(icon: "heart.fill", tint: .pink, title: "已收藏歌曲",
                                            detail: "\(favorites.songs.count) 首")
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                            InsetDivider(leading: 72)

                            NavigationLink {
                                DownloadsView(showNowPlaying: $showNowPlaying)
                                    .environmentObject(player).environmentObject(downloads)
                            } label: {
                                categoryRow(icon: "arrow.down.circle.fill", tint: .green, title: "已下载",
                                            detail: downloads.items.isEmpty ? "暂无" : "\(downloads.items.count) 首")
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                            InsetDivider(leading: 72)

                            NavigationLink {
                                HistoryView(showNowPlaying: $showNowPlaying)
                                    .environmentObject(player)
                            } label: {
                                categoryRow(icon: "clock.fill", tint: .orange, title: "播放历史",
                                            detail: history.songs.isEmpty ? "暂无" : "\(history.songs.count) 首")
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                        }
                        .background { RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)) }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SectionTitle(text: "我的歌单")
                                Spacer()
                                Button {
                                    Haptics.tap(); showNewPlaylist = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.9))
                            }
                            .padding(.horizontal, 20)

                            if playlists.playlists.isEmpty {
                                Text("还没有歌单，点右上角 ＋ 新建")
                                    .font(.system(size: 14)).foregroundStyle(.secondary)
                                    .padding(.horizontal, 20).padding(.vertical, 8)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(playlists.playlists) { playlist in
                                        NavigationLink {
                                            UserPlaylistDetailView(playlistID: playlist.id, showNowPlaying: $showNowPlaying)
                                                .environmentObject(player).environmentObject(playlists)
                                                .environmentObject(favorites)
                                        } label: {
                                            HStack(spacing: 12) {
                                                CoverArtView(url: playlist.coverURL, size: 48, cornerRadius: 5)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(playlist.name).font(.system(size: 15))
                                                        .foregroundStyle(.primary).lineLimit(1)
                                                    Text("\(playlist.songs.count) 首")
                                                        .font(.system(size: 13)).foregroundStyle(.secondary)
                                                }
                                                Spacer(minLength: 0)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(.tertiary)
                                                    .padding(.trailing, 20)
                                            }
                                            .padding(.vertical, 6).padding(.leading, 20)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 150)
                    }
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationBarHidden(true)
        }
        .alert("新建歌单", isPresented: $showNewPlaylist) {
            TextField("歌单名称", text: $newPlaylistName)
            Button("取消", role: .cancel) { newPlaylistName = "" }
            Button("创建") {
                playlists.create(name: newPlaylistName)
                newPlaylistName = ""
                ToastCenter.shared.success("已创建")
            }
        }
    }

    private func categoryRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))
            Text(title).font(.system(size: 16)).foregroundStyle(.primary)
            Spacer(minLength: 0)
            Text(detail).font(.system(size: 14)).foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

// MARK: - 收藏

struct FavoritesView: View {
    @Binding var showNowPlaying: Bool
    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var selectedSong: Song?

    var body: some View {
        Group {
            if favorites.songs.isEmpty {
                EmptyStateView(icon: "heart", title: "还没有收藏", message: "在歌曲上点「收藏」就会出现在这里")
            } else {
                List {
                    ForEach(Array(favorites.songs.enumerated()), id: \.element.identityKey) { index, song in
                        SongRow(
                            song: song,
                            isCurrent: player.currentSong?.identityKey == song.identityKey,
                            isPlaying: player.isPlaying,
                            onTap: {
                                player.play(songs: favorites.songs, startAt: index)
                                showNowPlaying = true
                            },
                            onMore: { selectedSong = song }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { favorites.remove(at: $0) }
                }
                .listStyle(.plain)
                .compatScrollBackgroundHidden()
            }
        }
        .navigationTitle("已收藏歌曲")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player).environmentObject(favorites)
        }
    }
}

// MARK: - 下载

struct DownloadsView: View {
    @Binding var showNowPlaying: Bool
    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var downloads: DownloadStore

    private var songs: [Song] { downloads.items.map(\.song) }

    var body: some View {
        Group {
            if songs.isEmpty {
                EmptyStateView(icon: "arrow.down.circle", title: "还没有下载",
                               message: "在歌曲菜单里点「下载」即可离线收听")
            } else {
                List {
                    ForEach(Array(songs.enumerated()), id: \.element.identityKey) { index, song in
                        SongRow(
                            song: song,
                            isCurrent: player.currentSong?.identityKey == song.identityKey,
                            isPlaying: player.isPlaying,
                            onTap: {
                                if let local = downloads.fileURL(for: song) {
                                    player.play(songs: songs, startAt: index)
                                    player.playLocalFile(url: local, song: song)
                                } else {
                                    player.play(songs: songs, startAt: index)
                                }
                                showNowPlaying = true
                            },
                            onMore: nil
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        for index in offsets where index < songs.count { downloads.delete(songs[index]) }
                    }
                }
                .listStyle(.plain)
                .compatScrollBackgroundHidden()
            }
        }
        .navigationTitle("已下载")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 历史

struct HistoryView: View {
    @Binding var showNowPlaying: Bool
    @EnvironmentObject private var player: PlayerManager
    @ObservedObject private var history = PlayHistoryStore.shared

    var body: some View {
        Group {
            if history.songs.isEmpty {
                EmptyStateView(icon: "clock", title: "暂无播放记录", message: nil)
            } else {
                List {
                    ForEach(Array(history.songs.enumerated()), id: \.element.identityKey) { index, song in
                        SongRow(
                            song: song,
                            isCurrent: player.currentSong?.identityKey == song.identityKey,
                            isPlaying: player.isPlaying,
                            onTap: {
                                player.play(songs: history.songs, startAt: index)
                                showNowPlaying = true
                            },
                            onMore: nil
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .compatScrollBackgroundHidden()
            }
        }
        .navigationTitle("播放历史")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("清空") {
                    history.clear()
                    ToastCenter.shared.show("已清空播放历史")
                }
                .disabled(history.songs.isEmpty)
            }
        }
    }
}

// MARK: - 用户歌单详情

struct UserPlaylistDetailView: View {
    let playlistID: String
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var playlists: PlaylistStore
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var selectedSong: Song?

    private var playlist: UserPlaylist? { playlists.playlist(id: playlistID) }

    var body: some View {
        Group {
            if let playlist, !playlist.songs.isEmpty {
                List {
                    ForEach(Array(playlist.songs.enumerated()), id: \.element.identityKey) { index, song in
                        SongRow(
                            song: song,
                            isCurrent: player.currentSong?.identityKey == song.identityKey,
                            isPlaying: player.isPlaying,
                            onTap: {
                                player.play(songs: playlist.songs, startAt: index)
                                showNowPlaying = true
                            },
                            onMore: { selectedSong = song }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        for index in offsets where index < playlist.songs.count {
                            playlists.remove(song: playlist.songs[index], from: playlistID)
                        }
                    }
                }
                .listStyle(.plain)
                .compatScrollBackgroundHidden()
            } else {
                EmptyStateView(icon: "music.note.list", title: "歌单是空的",
                               message: "在歌曲菜单里「加入歌单」即可")
            }
        }
        .navigationTitle(playlist?.name ?? "歌单")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let playlist, !playlist.songs.isEmpty {
                    Button {
                        Haptics.success()
                        player.play(songs: playlist.songs, startAt: 0)
                        showNowPlaying = true
                    } label: { Image(systemName: "play.fill") }
                }
            }
        }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player).environmentObject(favorites)
        }
    }
}
