//
//  SongActionSheet.swift
//  AppleMusic
//
//  歌曲操作菜单。
//

import SwiftUI

struct SongActionSheet: View {
    let song: Song
    @Binding var isPresented: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var playlists: PlaylistStore

    @State private var showPlaylistPicker = false
    @State private var isDownloading = false

    private var isFavorite: Bool { favorites.contains(song) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CoverArtView(url: song.coverURL, size: 52, cornerRadius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Text(song.artists).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            actionRow(icon: "text.insert", title: "下一首播放") { player.playNext(song) }

            actionRow(
                icon: isFavorite ? "heart.fill" : "heart",
                title: isFavorite ? "取消收藏" : "收藏",
                tint: isFavorite ? .red : nil
            ) {
                let liked = favorites.toggle(song)
                ToastCenter.shared.show(liked ? "已收藏" : "已取消收藏", icon: liked ? "heart.fill" : "heart")
            }

            actionRow(icon: "text.badge.plus", title: "加入歌单") { showPlaylistPicker = true }

            actionRow(icon: "arrow.down.circle", title: isDownloading ? "下载中…" : "下载") { download() }

            actionRow(icon: "square.and.arrow.up", title: "分享") { share() }

            Divider()

            Button {
                isPresented = false
            } label: {
                Text("取消")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.98))
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerSheet(song: song, isPresented: $showPlaylistPicker)
                .environmentObject(playlists)
        }
    }

    private func actionRow(icon: String, title: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { action() }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(tint ?? Color.primary)
                    .frame(width: 26)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(tint ?? Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
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
                case .failure(let message): ToastCenter.shared.error(message)
                }
            }
        }
    }

    private func share() {
        let items: [Any] = ["\(song.name) - \(song.artists)"]
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            activity.popoverPresentationController?.sourceView = presenter.view
            presenter.present(activity, animated: true)
        }
    }
}

// MARK: - 选择歌单

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
                            Text("新建歌单").foregroundStyle(.primary)
                        }
                    }
                }

                if !playlists.playlists.isEmpty {
                    Section("我的歌单") {
                        ForEach(playlists.playlists) { playlist in
                            Button {
                                let added = playlists.add(song, to: playlist.id)
                                ToastCenter.shared.show(
                                    added ? "已加入「\(playlist.name)」" : "已在该歌单中",
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
            .navigationTitle("加入歌单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { isPresented = false }
                }
            }
        }
        .alert("新建歌单", isPresented: $showNewPlaylist) {
            TextField("歌单名称", text: $newName)
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
