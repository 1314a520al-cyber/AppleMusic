//
//  RootView.swift
//  AppleMusic
//
//  根视图：页面 + 悬浮底栏 + 迷你播放条 + 全屏播放页。
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var settings: AppSettings

    @State private var selection: TabItem = .home
    @State private var showNowPlaying = false

    var body: some View {
        ZStack(alignment: .bottom) {

            Group {
                switch selection {
                case .home:    HomeView(showNowPlaying: $showNowPlaying)
                case .radio:   RadioView(showNowPlaying: $showNowPlaying)
                case .search:  SearchView(showNowPlaying: $showNowPlaying)
                case .library: LibraryView(showNowPlaying: $showNowPlaying)
                case .mine:    MineView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 8) {
                if settings.showMiniPlayer, player.currentSong != nil {
                    MiniPlayerBar(showNowPlaying: $showNowPlaying)
                        .padding(.horizontal, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                FloatingTabBar(
                    selection: $selection,
                    miniPlayerVisible: settings.showMiniPlayer && player.currentSong != nil
                )
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.85), value: player.currentSong?.identityKey)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
                .environmentObject(player)
                .environmentObject(player.clock)
        }
        .onAppear { Haptics.prepare() }
    }
}
