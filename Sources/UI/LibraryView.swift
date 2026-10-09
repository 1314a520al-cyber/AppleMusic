//
//  LibraryView.swift
//  AppleMusic
//
//  「资料库」。
//
//  结构（对照参考图）：
//    左上「编辑」按钮，中间偏左「资料库」大标题，右上圆形头像
//    红色图标的分类列表（播放列表 / 艺人 / 专辑 / 歌曲 / 类型 / 作曲者）
//    「最近添加」双列大卡
//

import SwiftUI

struct LibraryView: View {
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var playlists: PlaylistStore
    @EnvironmentObject private var downloads: DownloadStore
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var history = PlayHistoryStore.shared

    @State private var showNewPlaylist = false
    @State private var newPlaylistName = ""
    @State private var showEditMode = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        header

                        // 分类列表
                        VStack(spacing: 0) {
                            categoryRow(icon: "music.note.list", title: "播放列表") { }
                            InsetDivider(leading: 56)
                            categoryRow(icon: "music.mic", title: "艺人") { }
                            InsetDivider(leading: 56)
                            categoryRow(icon: "square.stack", title: "专辑") { }
                            InsetDivider(leading: 56)
                            categoryRow(icon: "music.note", title: "歌曲") { }
                            InsetDivider(leading: 56)
                            categoryRow(icon: "guitars", title: "类型") { }
                            InsetDivider(leading: 56)
                            categoryRow(icon: "music.note.tv", title: "作曲者") { }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        }
                        .padding(.horizontal, 16)

                        // 已收藏 / 已下载 / 历史 快捷入口
                        VStack(spacing: 0) {
                            NavigationLink {
                                FavoritesView(showNowPlaying: $showNowPlaying)
                                    .environmentObject(player).environmentObject(favorites)
                            } label: {
                                categoryRow(icon: "star.fill", title: "已喜爱",
                                            detail: "\(favorites.songs.count) 首") { }
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                            InsetDivider(leading: 56)

                            NavigationLink {
                                DownloadsView(showNowPlaying: $showNowPlaying)
                                    .environmentObject(player).environmentObject(downloads)
                            } label: {
                                categoryRow(icon: "arrow.down.circle.fill", title: "已下载",
                                            detail: downloads.items.isEmpty ? nil : "\(downloads.items.count) 首") { }
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                            InsetDivider(leading: 56)

                            NavigationLink {
                                HistoryView(showNowPlaying: $showNowPlaying)
                                    .environmentObject(player)
                            } label: {
                                categoryRow(icon: "clock.fill", title: "最近播放",
                                            detail: history.songs.isEmpty ? nil : "\(history.songs.count) 首") { }
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        }
                        .padding(.horizontal, 16)

                        // 我的播放列表
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("我的播放列表")
                                    .font(.system(size: 22, weight: .bold))
                                Spacer()
                                Button {
                                    Haptics.tap(); showNewPlaylist = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(settings.accent.color)
                                        .frame(width: 34, height: 34)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.9))
                            }
                            .padding(.horizontal, 16)

                            if playlists.playlists.isEmpty {
                                Text("还没有播放列表")
                                    .font(.system(size: 14)).foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(playlists.playlists) { playlist in
                                        NavigationLink {
                                            UserPlaylistDetailView(playlistID: playlist.id, showNowPlaying: $showNowPlaying)
                                                .environmentObject(player).environmentObject(playlists)
                                                .environmentObject(favorites)
                                        } label: {
                                            HStack(spacing: 12) {
                                                CoverArtView(url: playlist.coverURL, size: 48, cornerRadius: 6)
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
                                                    .padding(.trailing, 16)
                                            }
                                            .padding(.vertical, 6).padding(.leading, 16)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                    }
                                }
                            }
                        }

                        // 最近添加
                        if !history.songs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("最近添加")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(.horizontal, 16)

                                LazyVGrid(columns: columns, spacing: 18) {
                                    ForEach(Array(history.songs.prefix(6).enumerated()), id: \.element.identityKey) { index, song in
                                        Button {
                                            Haptics.success()
                                            player.play(songs: history.songs, startAt: index)
                                            showNowPlaying = true
                                        } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                CoverArtView(url: song.coverURL, size: 160, cornerRadius: 8)
                                                    .frame(maxWidth: .infinity)
                                                    .aspectRatio(1, contentMode: .fit)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(song.name)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(.primary)
                                                        .lineLimit(1)
                                                    Text(song.artists)
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                        .buttonStyle(PressableButtonStyle(scale: 0.97))
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer(minLength: 170)
                    }
                    .padding(.top, 6)
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationBarHidden(true)
        }
        .alert("新建播放列表", isPresented: $showNewPlaylist) {
            TextField("名称", text: $newPlaylistName)
            Button("取消", role: .cancel) { newPlaylistName = "" }
            Button("创建") {
                playlists.create(name: newPlaylistName)
                newPlaylistName = ""
                ToastCenter.shared.success("已创建")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    Haptics.tap()
                    ToastCenter.shared.show("长按列表可编辑排序")
                } label: {
                    Text("编辑")
                        .font(.system(size: 17))
                        .foregroundStyle(settings.accent.color)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.94))

                Spacer()

                if settings.showTopLeftAvatar {
                    AvatarButton()
                }
            }
            .padding(.horizontal, 16)

            Text("资料库")
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 16)
        }
        .padding(.top, 4)
    }

    private func categoryRow(icon: String, title: String, detail: String? = nil, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(settings.accent.color)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if let detail {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.trailing, 16)
        }
        .padding(.leading, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - 已喜爱

struct FavoritesView: View {
    @Binding var showNowPlaying: Bool
    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedSong: Song?

    var body: some View {
        Group {
            if favorites.songs.isEmpty {
                EmptyStateView(icon: "star", title: "还没有喜爱的歌曲",
                               message: "在歌曲菜单里点「喜爱」就会出现在这里")
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
                            onMore: settings.showSongRowMore ? { selectedSong = song } : nil
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
        .navigationTitle("已喜爱")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player).environmentObject(favorites)
        }
    }
}

// MARK: - 已下载

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

// MARK: - 最近播放

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
        .navigationTitle("最近播放")
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

// MARK: - 用户播放列表详情

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
                EmptyStateView(icon: "music.note.list", title: "播放列表是空的",
                               message: "在歌曲菜单里「添加到播放列表」即可")
            }
        }
        .navigationTitle(playlist?.name ?? "播放列表")
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
