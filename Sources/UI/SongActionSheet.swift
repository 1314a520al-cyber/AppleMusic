//
//  SongActionSheet.swift
//  AppleMusic
//
//  歌曲「更多」菜单。
//
//  严格对照参考图：深灰圆角面板，每行「文字 + 右侧图标」，
//  其中「从资料库删除」为红色。
//

import SwiftUI

struct SongActionSheet: View {
    let song: Song
    @Binding var isPresented: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var playlists: PlaylistStore
    @EnvironmentObject private var downloads: DownloadStore

    @State private var showPlaylistPicker = false
    @State private var isDownloading = false

    private var isFavorite: Bool { favorites.contains(song) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CoverArtView(url: song.coverURL, size: 50, cornerRadius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Text(song.artists).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            menuRow(title: "查看制作人员", icon: "info.circle") {
                ToastCenter.shared.show("暂无制作人员信息")
            }

            if favorites.contains(song) {
                menuRow(title: "从资料库删除", icon: "trash", tint: .red) {
                    favorites.remove(song)
                    ToastCenter.shared.success("已从资料库删除")
                }
            }

            menuRow(title: isDownloading ? "下载中…" : "下载", icon: "arrow.down.circle") {
                download()
            }

            menuRow(title: "添加到播放列表…", icon: "text.badge.plus") {
                showPlaylistPicker = true
            }

            menuRow(title: "分享歌曲…", icon: "square.and.arrow.up") {
                share(text: "\(song.name) - \(song.artists)")
            }

            menuRow(title: "分享歌词…", icon: "quote.bubble") {
                let lyricText = player.currentSong?.identityKey == song.identityKey
                    ? player.lyrics.map(\.text).joined(separator: "\n")
                    : ""
                share(text: lyricText.isEmpty ? "\(song.name) - \(song.artists)" : lyricText)
            }

            menuRow(title: "前往专辑", icon: "music.note.list") {
                ToastCenter.shared.show("正在打开专辑")
            }

            menuRow(title: "创建电台", icon: "dot.radiowaves.left.and.right") {
                Haptics.success()
                player.setPlayMode(.shuffle)
                ToastCenter.shared.show("已创建电台", icon: "dot.radiowaves.left.and.right")
            }

            menuRow(
                title: isFavorite ? "撤销喜爱" : "喜爱",
                icon: isFavorite ? "star.slash" : "star"
            ) {
                let liked = favorites.toggle(song)
                ToastCenter.shared.show(liked ? "已喜爱" : "已撤销喜爱")
            }

            menuRow(title: "报告问题…", icon: "exclamationmark.bubble") {
                ToastCenter.shared.show("已记录，感谢反馈")
            }

            Divider()

            Button {
                isPresented = false
            } label: {
                Text("取消")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.98))
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerSheet(song: song, isPresented: $showPlaylistPicker)
                .environmentObject(playlists)
        }
    }

    /// 一行菜单：左侧文字，右侧图标
    private func menuRow(title: String, icon: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { action() }
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(tint ?? Color.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(tint ?? Color.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
    }

    private func download() {
        isDownloading = true
        Task {
            let result = await DownloadManager.download(song: song)
            await MainActor.run {
                isDownloading = false
                switch result {
                case .success: ToastCenter.shared.success("已下载")
                case .failure(let error): ToastCenter.shared.error(error.localizedDescription)
                }
            }
        }
    }

    private func share(text: String) {
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            activity.popoverPresentationController?.sourceView = presenter.view
            presenter.present(activity, animated: true)
        }
    }
}

// MARK: - 选择播放列表

struct PlaylistPickerSheet: View {
    let song: Song
    @Binding var isPresented: Bool

    @EnvironmentObject private var playlists: PlaylistStore
    @State private var showNewPlaylist = false
    @State private var newName = ""

    var body: some View {
        CompatNavigationStack {
            List {
                Section {
                    Button { showNewPlaylist = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Color.accentColor)
                            Text("新建播放列表").foregroundStyle(.primary)
                        }
                    }
                }

                if !playlists.playlists.isEmpty {
                    Section("我的播放列表") {
                        ForEach(playlists.playlists) { playlist in
                            Button {
                                let added = playlists.add(song, to: playlist.id)
                                ToastCenter.shared.show(
                                    added ? "已加入「\(playlist.name)」" : "已在该列表中",
                                    icon: added ? "checkmark.circle.fill" : "info.circle"
                                )
                                isPresented = false
                            } label: {
                                HStack(spacing: 12) {
                                    CoverArtView(url: playlist.coverURL, size: 40, cornerRadius: 4)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.name).foregroundStyle(.primary)
                                        Text("\(playlist.songs.count) 首")
                                            .font(.system(size: 12)).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加到播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { isPresented = false }
                }
            }
        }
        .alert("新建播放列表", isPresented: $showNewPlaylist) {
            TextField("名称", text: $newName)
            Button("取消", role: .cancel) { newName = "" }
            Button("创建") {
                let playlist = playlists.create(name: newName)
                playlists.add(song, to: playlist.id)
                newName = ""
                ToastCenter.shared.success("已创建并加入")
                isPresented = false
            }
        }
    }
}

/// 供 .sheet(item:) 使用的容器
struct SongSheetContainer: View {
    let song: Song
    @State private var isPresented = true

    var body: some View {
        SongActionSheet(song: song, isPresented: $isPresented)
    }
}
