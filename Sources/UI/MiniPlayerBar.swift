//
//  MiniPlayerBar.swift
//  AppleMusic
//
//  悬浮迷你播放条。
//

import SwiftUI

struct MiniPlayerBar: View {
    @Binding var showNowPlaying: Bool
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        if let song = player.currentSong {
            ZStack(alignment: .top) {
                HStack(spacing: 10) {
                    CoverArtView(url: song.coverURL, size: 38, cornerRadius: 4)

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

                    Button {
                        player.togglePlayPause()
                    } label: {
                        PlayPauseIcon(isPlaying: player.isPlaying, size: 20)
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
                            .font(.system(size: 17))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))
                    .padding(.trailing, 2)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 10)

                // 顶部进度线
                GeometryReader { geo in
                    let ratio = player.clock.duration > 0
                        ? min(1, max(0, player.clock.progress / player.clock.duration))
                        : 0
                    Rectangle()
                        .fill(Color.accentColor)
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
                Capsule(style: .continuous).strokeBorder(.white.opacity(0.20), lineWidth: 0.7)
            }
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .white.opacity(0.03), .black.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
    }
}
