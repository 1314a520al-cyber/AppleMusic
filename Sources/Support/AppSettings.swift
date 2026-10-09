//
//  AppSettings.swift
//  AppleMusic
//
//  全局设置中心。
//
//  设计原则：界面上每一个可见元素都对应一个开关，
//  用户可以在设置里自由决定显示 / 隐藏，并可调整底栏顺序。
//

import Foundation
import SwiftUI

// MARK: - 主题模式

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .dark:   return "深色"
        case .light:  return "浅色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}

// MARK: - 主题色

enum AccentColorOption: String, CaseIterable, Identifiable {
    case red
    case pink
    case orange
    case yellow
    case green
    case mint
    case teal
    case blue
    case indigo
    case purple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .red:    return "红色"
        case .pink:   return "粉色"
        case .orange: return "橙色"
        case .yellow: return "黄色"
        case .green:  return "绿色"
        case .mint:   return "薄荷"
        case .teal:   return "青色"
        case .blue:   return "蓝色"
        case .indigo: return "靛蓝"
        case .purple: return "紫色"
        }
    }

    var color: Color {
        switch self {
        case .red:    return Color(red: 0.98, green: 0.24, blue: 0.26)
        case .pink:   return Color(red: 0.98, green: 0.35, blue: 0.55)
        case .orange: return Color(red: 0.98, green: 0.55, blue: 0.20)
        case .yellow: return Color(red: 0.98, green: 0.78, blue: 0.20)
        case .green:  return Color(red: 0.30, green: 0.78, blue: 0.35)
        case .mint:   return Color(red: 0.30, green: 0.82, blue: 0.72)
        case .teal:   return Color(red: 0.25, green: 0.70, blue: 0.80)
        case .blue:   return Color(red: 0.20, green: 0.52, blue: 0.98)
        case .indigo: return Color(red: 0.40, green: 0.38, blue: 0.92)
        case .purple: return Color(red: 0.68, green: 0.36, blue: 0.92)
        }
    }
}

// MARK: - 底栏项目（可勾选 + 可排序）

enum TabItem: String, CaseIterable, Identifiable, Codable {
    case home
    case browse
    case radio
    case library
    case search
    case mine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:    return "主页"
        case .browse:  return "浏览"
        case .radio:   return "广播"
        case .library: return "资料库"
        case .search:  return "搜索"
        case .mine:    return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house"
        case .browse:  return "square.grid.2x2"
        case .radio:   return "dot.radiowaves.left.and.right"
        case .library: return "square.stack"
        case .search:  return "magnifyingglass"
        case .mine:    return "person.crop.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:    return "house.fill"
        case .browse:  return "square.grid.2x2.fill"
        case .radio:   return "dot.radiowaves.left.and.right"
        case .library: return "square.stack.fill"
        case .search:  return "magnifyingglass"
        case .mine:    return "person.crop.circle.fill"
        }
    }
}

// MARK: - 设置中心

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // ---- 外观 ----
    @Published var themeMode: ThemeMode { didSet { save(themeMode.rawValue, "appleMusic.themeMode") } }
    @Published var accent: AccentColorOption { didSet { save(accent.rawValue, "appleMusic.accent") } }
    @Published var dynamicWallpaper: Bool { didSet { save(dynamicWallpaper, "appleMusic.dynamicWallpaper") } }
    @Published var highRefreshRate: Bool { didSet { save(highRefreshRate, "appleMusic.highRefreshRate") } }

    // ---- 底栏 ----
    @Published var enabledTabs: [TabItem] { didSet { saveTabs() } }
    @Published var showTabLabels: Bool { didSet { save(showTabLabels, "appleMusic.showTabLabels") } }
    @Published var floatingTabBar: Bool { didSet { save(floatingTabBar, "appleMusic.floatingTabBar") } }

    // ---- 顶部栏元素 ----
    @Published var showTopLeftAvatar: Bool { didSet { save(showTopLeftAvatar, "appleMusic.showTopLeftAvatar") } }
    @Published var showTopRightButton: Bool { didSet { save(showTopRightButton, "appleMusic.showTopRightButton") } }
    @Published var showPlatformSwitcher: Bool { didSet { save(showPlatformSwitcher, "appleMusic.showPlatformSwitcher") } }

    // ---- 迷你播放条 ----
    @Published var showMiniPlayer: Bool { didSet { save(showMiniPlayer, "appleMusic.showMiniPlayer") } }
    @Published var showMiniPlayerStar: Bool { didSet { save(showMiniPlayerStar, "appleMusic.showMiniPlayerStar") } }
    @Published var showMiniPlayerMore: Bool { didSet { save(showMiniPlayerMore, "appleMusic.showMiniPlayerMore") } }

    // ---- 播放页元素 ----
    @Published var showNowPlayingQueue: Bool { didSet { save(showNowPlayingQueue, "appleMusic.showNowPlayingQueue") } }
    @Published var showNowPlayingVolume: Bool { didSet { save(showNowPlayingVolume, "appleMusic.showNowPlayingVolume") } }
    @Published var showNowPlayingBottomBar: Bool { didSet { save(showNowPlayingBottomBar, "appleMusic.showNowPlayingBottomBar") } }
    @Published var showNowPlayingModeButtons: Bool { didSet { save(showNowPlayingModeButtons, "appleMusic.showNowPlayingModeButtons") } }

    // ---- 主页板块 ----
    @Published var showHomeRecommend: Bool { didSet { save(showHomeRecommend, "appleMusic.showHomeRecommend") } }
    @Published var showHomeRoam: Bool { didSet { save(showHomeRoam, "appleMusic.showHomeRoam") } }
    @Published var showHomeRanking: Bool { didSet { save(showHomeRanking, "appleMusic.showHomeRanking") } }
    @Published var showHomeNewAlbums: Bool { didSet { save(showHomeNewAlbums, "appleMusic.showHomeNewAlbums") } }

    // ---- 歌曲行 ----
    @Published var showSongRowCover: Bool { didSet { save(showSongRowCover, "appleMusic.showSongRowCover") } }
    @Published var showSongRowMore: Bool { didSet { save(showSongRowMore, "appleMusic.showSongRowMore") } }
    @Published var showNowPlayingBars: Bool { didSet { save(showNowPlayingBars, "appleMusic.showNowPlayingBars") } }

    // ---- 我的页面入口 ----
    @Published var showSourceEntry: Bool { didSet { save(showSourceEntry, "appleMusic.showSourceEntry") } }
    @Published var showCacheEntry: Bool { didSet { save(showCacheEntry, "appleMusic.showCacheEntry") } }
    @Published var showQualityEntry: Bool { didSet { save(showQualityEntry, "appleMusic.showQualityEntry") } }
    @Published var showRewardEntry: Bool { didSet { save(showRewardEntry, "appleMusic.showRewardEntry") } }
    @Published var showGroupEntry: Bool { didSet { save(showGroupEntry, "appleMusic.showGroupEntry") } }
    @Published var showDownloadsEntry: Bool { didSet { save(showDownloadsEntry, "appleMusic.showDownloadsEntry") } }

    // ---- 其他 ----
    @Published var hapticEnabled: Bool { didSet { save(hapticEnabled, "appleMusic.hapticEnabled") } }
    @Published var autoPlayOnStart: Bool { didSet { save(autoPlayOnStart, "appleMusic.autoPlayOnStart") } }
    @Published var showEqualizer: Bool { didSet { save(showEqualizer, "appleMusic.showEqualizer") } }

    private init() {
        let d = UserDefaults.standard

        themeMode = ThemeMode(rawValue: d.string(forKey: "appleMusic.themeMode") ?? "") ?? .dark
        accent = AccentColorOption(rawValue: d.string(forKey: "appleMusic.accent") ?? "") ?? .red
        dynamicWallpaper = d.object(forKey: "appleMusic.dynamicWallpaper") as? Bool ?? true
        highRefreshRate = d.object(forKey: "appleMusic.highRefreshRate") as? Bool ?? true

        if let raw = d.stringArray(forKey: "appleMusic.enabledTabs"), !raw.isEmpty {
            let items = raw.compactMap { TabItem(rawValue: $0) }
            enabledTabs = items.isEmpty ? [.home, .radio, .search] : items
        } else {
            enabledTabs = [.home, .radio, .search]
        }
        showTabLabels = d.object(forKey: "appleMusic.showTabLabels") as? Bool ?? false
        floatingTabBar = d.object(forKey: "appleMusic.floatingTabBar") as? Bool ?? true

        showTopLeftAvatar = d.object(forKey: "appleMusic.showTopLeftAvatar") as? Bool ?? true
        showTopRightButton = d.object(forKey: "appleMusic.showTopRightButton") as? Bool ?? true
        showPlatformSwitcher = d.object(forKey: "appleMusic.showPlatformSwitcher") as? Bool ?? true

        showMiniPlayer = d.object(forKey: "appleMusic.showMiniPlayer") as? Bool ?? true
        showMiniPlayerStar = d.object(forKey: "appleMusic.showMiniPlayerStar") as? Bool ?? true
        showMiniPlayerMore = d.object(forKey: "appleMusic.showMiniPlayerMore") as? Bool ?? true

        showNowPlayingQueue = d.object(forKey: "appleMusic.showNowPlayingQueue") as? Bool ?? true
        showNowPlayingVolume = d.object(forKey: "appleMusic.showNowPlayingVolume") as? Bool ?? true
        showNowPlayingBottomBar = d.object(forKey: "appleMusic.showNowPlayingBottomBar") as? Bool ?? true
        showNowPlayingModeButtons = d.object(forKey: "appleMusic.showNowPlayingModeButtons") as? Bool ?? true

        showHomeRecommend = d.object(forKey: "appleMusic.showHomeRecommend") as? Bool ?? true
        showHomeRoam = d.object(forKey: "appleMusic.showHomeRoam") as? Bool ?? true
        showHomeRanking = d.object(forKey: "appleMusic.showHomeRanking") as? Bool ?? true
        showHomeNewAlbums = d.object(forKey: "appleMusic.showHomeNewAlbums") as? Bool ?? true

        showSongRowCover = d.object(forKey: "appleMusic.showSongRowCover") as? Bool ?? true
        showSongRowMore = d.object(forKey: "appleMusic.showSongRowMore") as? Bool ?? true
        showNowPlayingBars = d.object(forKey: "appleMusic.showNowPlayingBars") as? Bool ?? true

        showSourceEntry = d.object(forKey: "appleMusic.showSourceEntry") as? Bool ?? true
        showCacheEntry = d.object(forKey: "appleMusic.showCacheEntry") as? Bool ?? true
        showQualityEntry = d.object(forKey: "appleMusic.showQualityEntry") as? Bool ?? true
        showRewardEntry = d.object(forKey: "appleMusic.showRewardEntry") as? Bool ?? true
        showGroupEntry = d.object(forKey: "appleMusic.showGroupEntry") as? Bool ?? true
        showDownloadsEntry = d.object(forKey: "appleMusic.showDownloadsEntry") as? Bool ?? true

        hapticEnabled = d.object(forKey: "appleMusic.hapticEnabled") as? Bool ?? true
        autoPlayOnStart = d.object(forKey: "appleMusic.autoPlayOnStart") as? Bool ?? false
        showEqualizer = d.object(forKey: "appleMusic.showEqualizer") as? Bool ?? true
    }

    private func save(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func saveTabs() {
        UserDefaults.standard.set(enabledTabs.map { $0.rawValue }, forKey: "appleMusic.enabledTabs")
    }

    /// 底栏可用项（保证至少一个）
    var activeTabs: [TabItem] {
        enabledTabs.isEmpty ? [.home, .search] : enabledTabs
    }

    func toggleTab(_ tab: TabItem) {
        if let index = enabledTabs.firstIndex(of: tab) {
            guard enabledTabs.count > 1 else { return }   // 至少保留一个
            enabledTabs.remove(at: index)
        } else {
            var list = enabledTabs
            list.append(tab)
            let order = TabItem.allCases
            enabledTabs = list.sorted {
                (order.firstIndex(of: $0) ?? 0) < (order.firstIndex(of: $1) ?? 0)
            }
        }
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        enabledTabs.move(fromOffsets: source, toOffset: destination)
    }

    /// 恢复全部默认
    func resetToDefaults() {
        themeMode = .dark
        accent = .red
        dynamicWallpaper = true
        highRefreshRate = true
        enabledTabs = [.home, .radio, .search]
        showTabLabels = false
        floatingTabBar = true

        showTopLeftAvatar = true
        showTopRightButton = true
        showPlatformSwitcher = true

        showMiniPlayer = true
        showMiniPlayerStar = true
        showMiniPlayerMore = true

        showNowPlayingQueue = true
        showNowPlayingVolume = true
        showNowPlayingBottomBar = true
        showNowPlayingModeButtons = true

        showHomeRecommend = true
        showHomeRoam = true
        showHomeRanking = true
        showHomeNewAlbums = true

        showSongRowCover = true
        showSongRowMore = true
        showNowPlayingBars = true

        showSourceEntry = true
        showCacheEntry = true
        showQualityEntry = true
        showRewardEntry = true
        showGroupEntry = true
        showDownloadsEntry = true

        hapticEnabled = true
        autoPlayOnStart = false
        showEqualizer = true
    }
}
