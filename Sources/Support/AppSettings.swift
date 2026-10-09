//
//  AppSettings.swift
//  AppleMusic
//
//  全局设置：所有功能开关都集中在这里，设置页可自由开/关。
//

import Foundation
import SwiftUI

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // MARK: - 开关（设置页自由开关）

    @Published var hapticEnabled: Bool          { didSet { save(hapticEnabled, "appleMusic.hapticEnabled") } }
    @Published var showMiniPlayer: Bool          { didSet { save(showMiniPlayer, "appleMusic.showMiniPlayer") } }
    @Published var showTabLabels: Bool           { didSet { save(showTabLabels, "appleMusic.showTabLabels") } }
    @Published var showLyricsInPlayer: Bool      { didSet { save(showLyricsInPlayer, "appleMusic.showLyricsInPlayer") } }
    @Published var showRewardEntry: Bool         { didSet { save(showRewardEntry, "appleMusic.showRewardEntry") } }
    @Published var showGroupEntry: Bool          { didSet { save(showGroupEntry, "appleMusic.showGroupEntry") } }
    @Published var showSourceEntry: Bool         { didSet { save(showSourceEntry, "appleMusic.showSourceEntry") } }
    @Published var showCacheEntry: Bool          { didSet { save(showCacheEntry, "appleMusic.showCacheEntry") } }
    @Published var showQualityEntry: Bool        { didSet { save(showQualityEntry, "appleMusic.showQualityEntry") } }
    @Published var showDownloadsEntry: Bool      { didSet { save(showDownloadsEntry, "appleMusic.showDownloadsEntry") } }
    @Published var autoPlayOnStart: Bool         { didSet { save(autoPlayOnStart, "appleMusic.autoPlayOnStart") } }
    @Published var showNowPlayingBars: Bool      { didSet { save(showNowPlayingBars, "appleMusic.showNowPlayingBars") } }

    private init() {
        let d = UserDefaults.standard
        hapticEnabled = d.object(forKey: "appleMusic.hapticEnabled") as? Bool ?? true
        showMiniPlayer = d.object(forKey: "appleMusic.showMiniPlayer") as? Bool ?? true
        showTabLabels = d.object(forKey: "appleMusic.showTabLabels") as? Bool ?? true
        showLyricsInPlayer = d.object(forKey: "appleMusic.showLyricsInPlayer") as? Bool ?? true
        showRewardEntry = d.object(forKey: "appleMusic.showRewardEntry") as? Bool ?? true
        showGroupEntry = d.object(forKey: "appleMusic.showGroupEntry") as? Bool ?? true
        showSourceEntry = d.object(forKey: "appleMusic.showSourceEntry") as? Bool ?? true
        showCacheEntry = d.object(forKey: "appleMusic.showCacheEntry") as? Bool ?? true
        showQualityEntry = d.object(forKey: "appleMusic.showQualityEntry") as? Bool ?? true
        showDownloadsEntry = d.object(forKey: "appleMusic.showDownloadsEntry") as? Bool ?? true
        autoPlayOnStart = d.object(forKey: "appleMusic.autoPlayOnStart") as? Bool ?? false
        showNowPlayingBars = d.object(forKey: "appleMusic.showNowPlayingBars") as? Bool ?? true
    }

    private func save(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    /// 恢复默认
    func resetToDefaults() {
        hapticEnabled = true
        showMiniPlayer = true
        showTabLabels = true
        showLyricsInPlayer = true
        showRewardEntry = true
        showGroupEntry = true
        showSourceEntry = true
        showCacheEntry = true
        showQualityEntry = true
        showDownloadsEntry = true
        autoPlayOnStart = false
        showNowPlayingBars = true
    }
}
