//
//  MiniPlayerBar.swift
//  AppleMusic
//
//  悬浮迷你播放条。
//  布局与参考图一致：封面 + 歌名/歌手 + 星标 + 三个控制键 + 更多。
//  星标 / 更多按钮的显示由设置控制。
//

import SwiftUI

struct MiniPlayerBar: View {
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var settings: AppSettings

    @State private var selectedSong: Song?

    private var song: Song? { player.currentSong }

    var body: some View {
        if let song {
            ZStack(alignment: .top) {
                HStack(spacing: 10) {
                    CoverArtView(url: song.coverURL, size: 40, cornerRadius: 6)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(song.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(song.artists.isEmpty ? song.album : song.artists)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    // 星标（收藏）
                    if settings.showMiniPlayerStar {
                        Button {
                            Haptics.tap()
                            let liked = favorites.toggle(song)
                            ToastCenter.shared.show(liked ? "已收藏" : "已取消收藏",
                                                    icon: liked ? "star.fill" : "star")
                        } label: {
                            Image(systemName: favorites.contains(song) ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundStyle(favorites.contains(song) ? settings.accent.color : Color.secondary)
                                .frame(width: 34, height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))
                    }

                    // 上一首 / 播放暂停 / 下一首
                    HStack(spacing: 0) {
                        Button {
                            Haptics.tap()
                            player.previous()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                                .frame(width: 34, height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))

                        Button {
                            player.togglePlayPause()
                        } label: {
                            PlayPauseIcon(isPlaying: player.isPlaying, size: 19)
                                .foregroundStyle(.primary)
                                .frame(width: 38, height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))

                        Button {
                            Haptics.tap()
                            player.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                                .frame(width: 34, height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))
                    }

                    // 更多
                    if settings.showMiniPlayerMore {
                        Button {
                            Haptics.tap()
                            selectedSong = song
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 38)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))
                        .padding(.trailing, 2)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)

                // 顶部进度线
                GeometryReader { geo in
                    let ratio = player.clock.duration > 0
                        ? min(1, max(0, player.clock.progress / player.clock.duration))
                        : 0
                    Rectangle()
                        .fill(settings.accent.color)
                        .frame(width: geo.size.width * CGFloat(ratio), height: 2)
                }
                .frame(height: 2)
            }
            .background { glassBackground }
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                showNowPlaying = true
            }
            .sheet(item: $selectedSong) { item in
                SongSheetContainer(song: item)
                    .environmentObject(player)
                    .environmentObject(favorites)
            }
        }
    }

    private var glassBackground: some View {
        Capsule(style: .continuous)
            .fill(.clear)
            .background {
                VisualEffectBlurView(style: .systemThinMaterial)
                    .clipShape(Capsule(style: .continuous))
            }
            .overlay {
                Capsule(style: .continuous).strokeBorder(.white.opacity(0.16), lineWidth: 0.7)
            }
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.14), .white.opacity(0.03), .black.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.24), radius: 16, y: 6)
    }
}
