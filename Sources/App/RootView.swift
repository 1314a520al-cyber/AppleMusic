//
//  RootView.swift
//  AppleMusic
//
//  根视图。
//
//  与参考图一致的层次：
//    页面内容（可滚动）
//    迷你播放条（贴底栏上方，深灰胶囊）
//    底部导航栏（默认贴底 5 项）
//
//  底栏显示哪些项目、是否悬浮、是否显示文字，均由 AppSettings 控制。
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
                case .browse:  BrowseView(showNowPlaying: $showNowPlaying)
                case .radio:   RadioView(showNowPlaying: $showNowPlaying)
                case .library: LibraryView(showNowPlaying: $showNowPlaying)
                case .search:  SearchView(showNowPlaying: $showNowPlaying)
                case .mine:    MineView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                if settings.showMiniPlayer, player.currentSong != nil {
                    MiniPlayerBar(showNowPlaying: $showNowPlaying)
                        .padding(.horizontal, settings.floatingTabBar ? 12 : 8)
                        .padding(.bottom, settings.floatingTabBar ? 8 : 6)
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
        .preferredColorScheme(settings.themeMode.colorScheme)
        .tint(settings.accent.color)
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
                .environmentObject(player)
                .environmentObject(player.clock)
        }
        .onAppear {
            Haptics.prepare()
            ensureSelectionValid()
        }
        .onChange(of: settings.enabledTabs) { _ in
            ensureSelectionValid()
        }
    }

    /// 当前选中的 Tab 若被隐藏，自动切到第一个可用项
    private func ensureSelectionValid() {
        let tabs = settings.activeTabs
        if !tabs.contains(selection), let first = tabs.first {
            selection = first
        }
    }
}
