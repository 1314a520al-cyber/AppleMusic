//
//  LyricsSheet.swift
//  AppleMusic
//

import SwiftUI

struct LyricsSheet: View {
    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var clock: PlaybackClock
    @Environment(\.dismiss) private var dismiss

    private var currentLineIndex: Int? {
        guard !player.lyrics.isEmpty else { return nil }
        var result: Int?
        for (index, line) in player.lyrics.enumerated() {
            if line.time <= clock.progress + 0.15 { result = index } else { break }
        }
        return result
    }

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                if player.isLoadingLyrics {
                    LoadingStateView(text: "正在载入歌词…")
                } else if player.lyrics.isEmpty {
                    EmptyStateView(icon: "quote.bubble", title: "暂无歌词", message: "这首歌暂时没有提供歌词")
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 18) {
                                Color.clear.frame(height: 120)
                                ForEach(Array(player.lyrics.enumerated()), id: \.element.id) { index, line in
                                    lyricLine(line, isCurrent: index == currentLineIndex)
                                        .id(index)
                                        .onTapGesture {
                                            Haptics.tap()
                                            player.seek(to: max(0, line.time - 0.1))
                                        }
                                }
                                Color.clear.frame(height: 160)
                            }
                            .padding(.horizontal, 24)
                        }
                        .compatScrollIndicatorsHidden()
                        .onChange(of: currentLineIndex) { newIndex in
                            guard let newIndex else { return }
                            withAnimation(.easeInOut(duration: 0.32)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
            .navigationTitle("歌词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }

    @ViewBuilder
    private func lyricLine(_ line: LyricLine, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(line.text.isEmpty ? "♪" : line.text)
                .font(.system(size: isCurrent ? 19 : 17, weight: isCurrent ? .bold : .regular))
                .foregroundStyle(isCurrent ? Color.primary : Color.secondary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.25), value: isCurrent)

            if let translation = line.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor.opacity(isCurrent ? 0.95 : 0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
