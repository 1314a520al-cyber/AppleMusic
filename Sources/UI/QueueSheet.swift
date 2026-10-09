//
//  QueueSheet.swift
//  AppleMusic
//

import SwiftUI

struct QueueSheet: View {
    @EnvironmentObject private var player: PlayerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                if player.queue.isEmpty {
                    EmptyStateView(icon: "list.bullet", title: "播放队列为空", message: nil)
                } else {
                    List {
                        Section {
                            ForEach(Array(player.queue.enumerated()), id: \.element.identityKey) { index, song in
                                Button {
                                    Haptics.tap()
                                    player.play(songs: player.queue, startAt: index)
                                } label: {
                                    HStack(spacing: 12) {
                                        CoverArtView(url: song.coverURL, size: 44, cornerRadius: 5)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(song.name)
                                                .font(.system(size: 15))
                                                .foregroundStyle(index == player.currentIndex ? Color.accentColor : Color.primary)
                                                .lineLimit(1)
                                            Text(song.artists)
                                                .font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Spacer(minLength: 0)
                                        if index == player.currentIndex {
                                            NowPlayingBars(color: .accentColor, animated: player.isPlaying)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { player.removeFromQueue(at: $0) }
                        } header: {
                            Text("待播放 · \(player.queue.count) 首")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("播放队列")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !player.queue.isEmpty {
                        Button("清空") {
                            player.clearQueue()
                            ToastCenter.shared.show("已清空队列")
                        }
                        .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}
