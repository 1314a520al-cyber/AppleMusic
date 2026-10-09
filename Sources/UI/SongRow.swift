//
//  SongRow.swift
//  AppleMusic
//
//  歌曲列表行。
//  封面 / 更多按钮的显示由设置控制（showSongRowCover / showSongRowMore）。
//  序号列右侧保留「三横线」拖动柄，与参考图一致。
//

import SwiftUI

struct SongRow: View {
    let song: Song
    /// 序号（传 nil 则不显示序号列）
    var index: Int? = nil
    var showCover: Bool? = nil
    var showArtist: Bool = true
    var isCurrent: Bool = false
    var isPlaying: Bool = false
    var showHandle: Bool = false
    var onTap: () -> Void
    var onMore: (() -> Void)?

    @EnvironmentObject private var downloads: DownloadStore
    @EnvironmentObject private var settings: AppSettings

    private var coverVisible: Bool { showCover ?? settings.showSongRowCover }

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap()
        }) {
            HStack(spacing: 12) {

                if let index {
                    Text("\(index)")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(isCurrent ? settings.accent.color : Color.secondary)
                        .frame(width: 26, alignment: .center)
                }

                if coverVisible {
                    ZStack(alignment: .bottomTrailing) {
                        CoverArtView(url: song.coverURL, size: 48, cornerRadius: 6)
                        if downloads.contains(song) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white, settings.accent.color)
                                .background(Circle().fill(Color(uiColor: .systemBackground)))
                                .offset(x: 3, y: 3)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name)
                        .font(.system(size: 15))
                        .foregroundStyle(isCurrent ? settings.accent.color : Color.primary)
                        .lineLimit(1)

                    if showArtist, !song.artists.isEmpty {
                        Text(song.artists)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                if isCurrent, settings.showNowPlayingBars {
                    NowPlayingBars(color: settings.accent.color, animated: isPlaying)
                        .padding(.trailing, onMore == nil ? 18 : 4)
                }

                if let onMore {
                    Button {
                        Haptics.tap()
                        onMore()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))
                } else if showHandle {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.vertical, 6)
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
    }
}
