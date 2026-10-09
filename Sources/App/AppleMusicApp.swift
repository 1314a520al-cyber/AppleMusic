//
//  AppleMusicApp.swift
//  AppleMusic
//

import SwiftUI
import UIKit

@main
struct AppleMusicApp: App {

    @StateObject private var player = PlayerManager.makeShared()
    @StateObject private var favorites = FavoritesStore.shared
    @StateObject private var playlists = PlaylistStore.shared
    @StateObject private var downloads = DownloadStore.shared
    @StateObject private var settings = AppSettings.shared

    init() {
        UserDefaults.standard.register(defaults: [
            "appleMusic.hapticEnabled": true,
            "appleMusic.audioQuality": AudioQuality.exhigh.rawValue
        ])
        configureURLCache()
        configureNavigationAppearance()
        Haptics.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .environmentObject(player.clock)
                .environmentObject(favorites)
                .environmentObject(playlists)
                .environmentObject(downloads)
                .environmentObject(settings)
                .overlay(alignment: .bottom) {
                    ToastHostView(center: ToastCenter.shared)
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
                ) { _ in
                    // 内存警告：只清内存图片，磁盘缓存保留（下次仍秒开）
                    ImageLoader.shared.flushMemory()
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                ) { _ in
                    // 回到前台时检查缓存是否超限，超了就自动瘦身
                    Task { @MainActor in
                        CacheManager.enforceLimits()
                    }
                }
        }
    }

    /// 显式限制 URLCache 容量。
    /// 系统默认的磁盘缓存上限极大，音频流分片会把磁盘吃满（这是缓存暴涨的元凶之一）。
    private func configureURLCache() {
        let memoryCapacity = 16 * 1024 * 1024      // 16MB 内存
        let diskCapacity = 48 * 1024 * 1024        // 48MB 磁盘
        URLCache.shared = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "AppleMusicURLCache"
        )
    }

    private func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
