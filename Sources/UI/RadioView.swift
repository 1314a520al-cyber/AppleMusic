//
//  RadioView.swift
//  AppleMusic
//
//  「广播」：电台卡片网格。
//

import SwiftUI

struct RadioView: View {
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore

    @State private var stations: [Playlist] = []
    @State private var isLoading = false
    @State private var errorText: String?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        CompatNavigationStack {
            ZStack {
                AmbienceBackdrop(tint: .purple)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("广播")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if isLoading && stations.isEmpty {
                            LoadingStateView(text: "正在获取电台…")
                        } else if stations.isEmpty {
                            VStack(spacing: 12) {
                                EmptyStateView(icon: "dot.radiowaves.left.and.right",
                                               title: "暂无电台", message: errorText ?? "稍后再试试")
                                Button { Task { await load() } } label: {
                                    Text("重新载入")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 26).padding(.vertical, 11)
                                        .background(Capsule().fill(Color.accentColor))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(stations) { station in
                                    NavigationLink {
                                        PlaylistDetailView(playlist: station, showNowPlaying: $showNowPlaying)
                                            .environmentObject(player)
                                            .environmentObject(favorites)
                                    } label: {
                                        StationCard(station: station)
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.97))
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 150)
                    }
                }
                .compatScrollIndicatorsHidden()
                .refreshable { await load() }
            }
            .navigationBarHidden(true)
        }
        .task { if stations.isEmpty { await load() } }
    }

    private func load() async {
        isLoading = true
        let list = (try? await NetEaseAPI.shared.personalizedPlaylists(limit: 20)) ?? []
        await MainActor.run {
            stations = list
            if list.isEmpty { errorText = "接口暂时不可用" }
            isLoading = false
        }
    }
}

struct StationCard: View {
    let station: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                CoverArtView(url: station.coverURL, size: 160, cornerRadius: 10)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(Color.accentColor.opacity(0.9)))
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(station.creatorName.isEmpty ? "精选电台" : station.creatorName)
                    .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }
}
