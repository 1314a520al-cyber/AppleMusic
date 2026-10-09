//
//  SongRow.swift
//  AppleMusic
//

import SwiftUI

struct SongRow: View {
    let song: Song
    var showCover: Bool = true
    var showArtist: Bool = true
    var isCurrent: Bool = false
    var isPlaying: Bool = false
    var onTap: () -> Void
    var onMore: (() -> Void)?

    @EnvironmentObject private var downloads: DownloadStore
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap()
        }) {
            HStack(spacing: 12) {
                if showCover {
                    ZStack(alignment: .bottomTrailing) {
                        CoverArtView(url: song.coverURL, size: 48, cornerRadius: 5)
                        if downloads.contains(song) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white, Color.accentColor)
                                .background(Circle().fill(Color(uiColor: .systemBackground)))
                                .offset(x: 3, y: 3)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name)
                        .font(.system(size: 15))
                        .foregroundStyle(isCurrent ? Color.accentColor : Color.primary)
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
                    NowPlayingBars(color: .accentColor, animated: isPlaying)
                        .padding(.trailing, onMore == nil ? 20 : 4)
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
                    .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 6)
            .padding(.leading, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
    }
}
