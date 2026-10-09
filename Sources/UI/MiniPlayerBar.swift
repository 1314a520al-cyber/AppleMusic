//
//  MiniPlayerBar.swift
//  AppleMusic
//
//  底部迷你播放条。
//
//  与参考图一致：深灰圆角矩形，左侧封面，中间歌名/歌手，
//  右侧「播放/暂停」与「下一首」两个按钮。
//  星标 / 更多按钮为可选（设置里默认关闭，与参考图一致）。
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
            HStack(spacing: 12) {
                CoverArtView(url: song.coverURL, size: 48, cornerRadius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(song.artists.isEmpty ? song.album : song.artists)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                HStack(spacing: 0) {
                    if settings.showMiniPlayerStar {
                        Button {
                            Haptics.tap()
                            let liked = favorites.toggle(song)
                            ToastCenter.shared.show(liked ? "已收藏" : "已取消收藏",
                                                    icon: liked ? "star.fill" : "star")
                        } label: {
                            Image(systemName: favorites.contains(song) ? "star.fill" : "star")
                                .font(.system(size: 17))
                                .foregroundStyle(favorites.contains(song) ? settings.accent.color : Color.secondary)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))
                    }

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))

                    Button {
                        Haptics.tap()
                        player.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 19))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))

                    if settings.showMiniPlayerMore {
                        Button {
                            Haptics.tap()
                            selectedSong = song
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.9))
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.leading, 8)
            .padding(.trailing, 4)
            .background { barBackground }
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

    /// 深灰圆角矩形（与参考图一致），开启悬浮时用毛玻璃胶囊
    @ViewBuilder
    private var barBackground: some View {
        if settings.floatingTabBar {
            Capsule(style: .continuous)
                .fill(.clear)
                .background {
                    VisualEffectBlurView(style: .systemThinMaterial)
                        .clipShape(Capsule(style: .continuous))
                }
                .overlay {
                    Capsule(style: .continuous).strokeBorder(.white.opacity(0.14), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.24), radius: 14, y: 5)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                }
        }
    }
}
