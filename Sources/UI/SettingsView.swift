//
//  SettingsView.swift
//  AppleMusic
//
//  设置页。
//
//  分区（与参考图一致）：
//    搜索设置框
//    账号与平台
//    外观与界面
//    播放与音效
//    数据管理
//
//  界面上每一个可见元素都能在这里自由开关。
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""

    var body: some View {
        CompatNavigationStack {
            ZStack {
                BackdropLayer()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // 搜索设置框
                        searchField
                            .padding(.horizontal, 16)
                            .padding(.top, 6)

                        // 账号与平台
                        if match("账号 登录 平台 显示") {
                            SettingsSection(title: "账号与平台") {
                                NavigationLink { AccountPlaceholderView() } label: {
                                    SettingsRow(icon: "person.crop.circle.fill", tint: settings.accent.color,
                                                title: "账号登录", detail: "网易云 / QQ / 酷狗")
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 60)
                                HStack {
                                    Image(systemName: "rectangle.2.swap")
                                        .font(.system(size: 15)).foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(settings.accent.color))
                                    Text("平台显示").font(.system(size: 16))
                                    Spacer()
                                    Text("右上角切换").font(.system(size: 13)).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                            }
                        }

                        // 外观与界面
                        if match("外观 主题 壁纸 刷新 底栏 界面") {
                            SettingsSection(title: "外观与界面") {
                                // 主题模式
                                Menu {
                                    ForEach(ThemeMode.allCases) { mode in
                                        Button(mode.title) {
                                            settings.themeMode = mode
                                            Haptics.select()
                                        }
                                    }
                                } label: {
                                    SettingsRow(icon: "circle.lefthalf.filled", tint: settings.accent.color,
                                                title: "主题模式", detail: settings.themeMode.title)
                                }

                                Divider().padding(.leading, 60)

                                // 主题色
                                Menu {
                                    ForEach(AccentColorOption.allCases) { option in
                                        Button {
                                            settings.accent = option
                                            Haptics.select()
                                        } label: {
                                            Label(option.title, systemImage: settings.accent == option ? "checkmark" : "circle.fill")
                                        }
                                    }
                                } label: {
                                    SettingsRow(icon: "paintpalette.fill", tint: settings.accent.color,
                                                title: "主题色", detail: settings.accent.title)
                                }

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "photo.on.rectangle.angled", tint: settings.accent.color,
                                               title: "动态壁纸", subtitle: "页面背景随主题色渐变",
                                               isOn: $settings.dynamicWallpaper)

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "speedometer", tint: settings.accent.color,
                                               title: "高刷新率", subtitle: "关闭可省电",
                                               isOn: $settings.highRefreshRate)

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "dock.rectangle", tint: settings.accent.color,
                                               title: "悬浮底栏", subtitle: "关闭则底栏贴底显示",
                                               isOn: $settings.floatingTabBar)

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "textformat", tint: settings.accent.color,
                                               title: "底栏显示文字", subtitle: nil,
                                               isOn: $settings.showTabLabels)

                                Divider().padding(.leading, 60)

                                NavigationLink { TabBarConfigView() } label: {
                                    SettingsRow(icon: "square.grid.2x2", tint: settings.accent.color,
                                                title: "底栏项目", detail: "\(settings.activeTabs.count) 个")
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        // 播放与音效
                        if match("播放 音效 音源 音质 均衡器 缓存") {
                            SettingsSection(title: "播放与音效") {
                                SettingsToggle(icon: "hand.tap.fill", tint: settings.accent.color,
                                               title: "触感反馈", subtitle: nil,
                                               isOn: $settings.hapticEnabled)

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "play.circle.fill", tint: settings.accent.color,
                                               title: "启动时自动续播", subtitle: nil,
                                               isOn: $settings.autoPlayOnStart)

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "waveform", tint: settings.accent.color,
                                               title: "正在播放指示条", subtitle: "歌曲行右侧跳动小条",
                                               isOn: $settings.showNowPlayingBars)
                            }
                        }

                        // 界面元素显示
                        if match("界面 元素 显示 迷你 顶部 歌曲行") {
                            SettingsSection(title: "界面元素显示") {
                                SettingsToggle(icon: "rectangle.bottomthird.inset.filled", tint: settings.accent.color,
                                               title: "迷你播放条", subtitle: nil,
                                               isOn: $settings.showMiniPlayer)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "star", tint: settings.accent.color,
                                               title: "迷你条 · 星标按钮", subtitle: nil,
                                               isOn: $settings.showMiniPlayerStar)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "ellipsis", tint: settings.accent.color,
                                               title: "迷你条 · 更多按钮", subtitle: nil,
                                               isOn: $settings.showMiniPlayerMore)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "person.circle", tint: settings.accent.color,
                                               title: "左上角头像", subtitle: nil,
                                               isOn: $settings.showTopLeftAvatar)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "ellipsis.circle", tint: settings.accent.color,
                                               title: "右上角按钮", subtitle: nil,
                                               isOn: $settings.showTopRightButton)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "rectangle.2.swap", tint: settings.accent.color,
                                               title: "音源切换菜单", subtitle: "右上角平台下拉",
                                               isOn: $settings.showPlatformSwitcher)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "photo", tint: settings.accent.color,
                                               title: "歌曲行封面", subtitle: nil,
                                               isOn: $settings.showSongRowCover)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "ellipsis", tint: settings.accent.color,
                                               title: "歌曲行更多按钮", subtitle: nil,
                                               isOn: $settings.showSongRowMore)
                            }
                        }

                        // 播放页元素
                        if match("播放页 队列 音量 歌词 电台") {
                            SettingsSection(title: "播放页元素") {
                                SettingsToggle(icon: "list.bullet", tint: settings.accent.color,
                                               title: "待播清单", subtitle: nil,
                                               isOn: $settings.showNowPlayingQueue)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "speaker.wave.2.fill", tint: settings.accent.color,
                                               title: "音量条", subtitle: nil,
                                               isOn: $settings.showNowPlayingVolume)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "shuffle", tint: settings.accent.color,
                                               title: "播放模式按钮", subtitle: "随机 / 循环 / 单曲",
                                               isOn: $settings.showNowPlayingModeButtons)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "quote.bubble", tint: settings.accent.color,
                                               title: "底部工具条", subtitle: "歌词 / 电台 / 队列",
                                               isOn: $settings.showNowPlayingBottomBar)
                            }
                        }

                        // 主页板块
                        if match("主页 板块 推荐 漫游 排行 新歌") {
                            SettingsSection(title: "主页板块") {
                                SettingsToggle(icon: "calendar", tint: settings.accent.color,
                                               title: "每日推荐", subtitle: nil,
                                               isOn: $settings.showHomeRecommend)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "infinity", tint: settings.accent.color,
                                               title: "私人漫游", subtitle: nil,
                                               isOn: $settings.showHomeRoam)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "chart.bar.fill", tint: settings.accent.color,
                                               title: "排行榜", subtitle: nil,
                                               isOn: $settings.showHomeRanking)
                                Divider().padding(.leading, 60)
                                SettingsToggle(icon: "sparkles", tint: settings.accent.color,
                                               title: "新歌上架", subtitle: nil,
                                               isOn: $settings.showHomeNewAlbums)
                            }
                        }

                        // 数据管理
                        if match("数据 管理 缓存 存储 备份") {
                            SettingsSection(title: "数据管理") {
                                NavigationLink { CacheManagerView() } label: {
                                    SettingsRow(icon: "trash.fill", tint: settings.accent.color,
                                                title: "清除缓存", detail: cacheText)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                                Divider().padding(.leading, 60)

                                SettingsToggle(icon: "arrow.down.circle.fill", tint: settings.accent.color,
                                               title: "保留已下载歌曲", subtitle: "清缓存时不动下载文件",
                                               isOn: .constant(true))

                                Divider().padding(.leading, 60)

                                Button {
                                    Haptics.tap()
                                    settings.resetToDefaults()
                                    ToastCenter.shared.success("已恢复默认设置")
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 15)).foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.gray))
                                        Text("恢复默认设置").font(.system(size: 16)).foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        Text("AppleMusic · 版本 \(appVersion)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var cacheText: String {
        CacheManager.formatted(CacheManager.totalSize())
    }

    /// 简单的设置项搜索过滤
    private func match(_ keywords: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return keywords.localizedCaseInsensitiveContains(q)
            || q.split(separator: " ").contains { keywords.localizedCaseInsensitiveContains(String($0)) }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15)).foregroundStyle(.secondary)
            TextField("搜索设置", text: $query)
                .font(.system(size: 16))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        }
    }
}

// MARK: - 分区容器

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content()
            }
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - 通用行

struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))
            Text(title).font(.system(size: 16)).foregroundStyle(.primary)
            Spacer(minLength: 0)
            if let detail {
                Text(detail).font(.system(size: 14)).foregroundStyle(.secondary).lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct SettingsToggle: View {
    let icon: String
    let tint: Color
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))

            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 16)).foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tint)
                .onChange(of: isOn) { _ in
                    Haptics.select()
                    if AppSettings.shared.hapticEnabled { }
                }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - 底栏项目配置（勾选 + 排序）

struct TabBarConfigView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        CompatNavigationStack {
            List {
                Section {
                    ForEach(settings.activeTabs) { tab in
                        HStack(spacing: 12) {
                            Image(systemName: tab.selectedIcon)
                                .font(.system(size: 16))
                                .foregroundStyle(settings.accent.color)
                                .frame(width: 28)
                            Text(tab.title).font(.system(size: 16))
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onMove { settings.moveTab(from: $0, to: $1) }
                } header: {
                    Text("已显示（长按拖动排序）")
                }

                Section {
                    ForEach(TabItem.allCases.filter { !settings.activeTabs.contains($0) }) { tab in
                        Button {
                            settings.toggleTab(tab)
                            Haptics.select()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28)
                                Text(tab.title).font(.system(size: 16)).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(settings.accent.color)
                            }
                        }
                    }
                } header: {
                    Text("可添加")
                } footer: {
                    Text("至少保留一个底栏项目。")
                }

                Section {
                    Button("移除全部并恢复默认") {
                        settings.enabledTabs = [.home, .radio, .search]
                        Haptics.success()
                    }
                    .foregroundStyle(settings.accent.color)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("底栏项目")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 账号占位页

struct AccountPlaceholderView: View {
    var body: some View {
        CompatNavigationStack {
            List {
                Section("网易云音乐") {
                    Text("未登录").foregroundStyle(.secondary)
                }
                Section("QQ 音乐") {
                    Text("未登录").foregroundStyle(.secondary)
                }
                Section("酷狗音乐") {
                    Text("未登录").foregroundStyle(.secondary)
                }
                Section {
                    Text("登录后可使用歌单同步、收藏同步等能力。")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("账号登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
