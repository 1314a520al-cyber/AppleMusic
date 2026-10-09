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
                    ImageLoader.shared.flushMemory()
                    URLCache.shared.removeAllCachedResponses()
                }
        }
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
