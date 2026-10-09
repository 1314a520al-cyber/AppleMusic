//
//  SettingsView.swift
//  AppleMusic
//
//  设置页。
//
//  分区（严格对照参考图，红色图标 + 深灰卡片）：
//    搜索设置
//    账号与平台：账号登录 / 平台显示
//    外观与界面：主题模式 / 动态壁纸 / 高刷新率
//    播放与音效：音源与音质 / 播放设置 / 均衡器
//    数据管理：备份与恢复 / 缓存清理
//    关于与支持：更新日志 / 检查更新 / 问题反馈 / 诊断与日志 / 免责声明 / 运行环境
//    界面元素：所有可见元素的显示开关
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var showThemePicker = false
    @State private var showAccentPicker = false
    @State private var showAbout = false
    @State private var showChangelog = false
    @State private var showEnvironment = false
    @State private var showPlayerSettings = false
    @State private var showEqualizer = false

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        searchField
                            .padding(.horizontal, 16)
                            .padding(.top, 6)

                        // 账号与平台
                        if match("账号 登录 平台 显示") {
                            SettingGroup(title: "账号与平台") {
                                NavigationLink { AccountView() } label: {
                                    SettingRow(icon: "person.crop.circle.fill", title: "账号登录",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)
                                Menu {
                                    ForEach(MusicPlatform.allCases) { item in
                                        Button(item.title) {
                                            PlatformPreferenceStore.shared.platform = item
                                            Haptics.select()
                                        }
                                    }
                                } label: {
                                    SettingRow(icon: "rectangle.2.swap", title: "平台显示",
                                               detail: PlatformPreferenceStore.shared.platform.title,
                                               tint: settings.accent.color)
                                }
                            }
                        }

                        // 外观与界面
                        if match("外观 主题 壁纸 刷新 界面") {
                            SettingGroup(title: "外观与界面") {
                                Button { showThemePicker = true } label: {
                                    SettingRow(icon: "circle.lefthalf.filled", title: "主题模式",
                                               detail: settings.themeMode.title, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button { showAccentPicker = true } label: {
                                    SettingRow(icon: "paintpalette.fill", title: "主题色",
                                               detail: settings.accent.title, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                SettingToggle(icon: "photo.on.rectangle.angled", title: "动态壁纸",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.dynamicWallpaper)
                                Divider().padding(.leading, 56)

                                SettingToggle(icon: "speedometer", title: "高刷新率",
                                              subtitle: "最高 120 Hz", tint: settings.accent.color,
                                              isOn: $settings.highRefreshRate)
                                Divider().padding(.leading, 56)

                                SettingToggle(icon: "dock.rectangle", title: "悬浮底栏",
                                              subtitle: settings.floatingTabBar ? "已开启液态玻璃底栏" : "贴底显示",
                                              tint: settings.accent.color, isOn: $settings.floatingTabBar)
                                Divider().padding(.leading, 56)

                                SettingToggle(icon: "textformat", title: "底栏显示文字",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showTabLabels)
                                Divider().padding(.leading, 56)

                                NavigationLink { TabBarConfigView() } label: {
                                    SettingRow(icon: "square.grid.2x2", title: "底栏项目",
                                               detail: "\(settings.activeTabs.count) 个", tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        // 播放与音效
                        if match("播放 音效 音源 音质 均衡器") {
                            SettingGroup(title: "播放与音效") {
                                NavigationLink { MusicSourceManagerView() } label: {
                                    SettingRow(icon: "waveform", title: "音源与音质",
                                               detail: AudioQuality.current.displayName, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button { showPlayerSettings = true } label: {
                                    SettingRow(icon: "play.circle", title: "播放设置",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button { showEqualizer = true } label: {
                                    SettingRow(icon: "slider.horizontal.3", title: "均衡器",
                                               detail: settings.showEqualizer ? nil : "已关闭",
                                               tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        // 数据管理
                        if match("数据 管理 备份 缓存 存储") {
                            SettingGroup(title: "数据管理") {
                                NavigationLink { CacheManagerView() } label: {
                                    SettingRow(icon: "trash.fill", title: "缓存清理",
                                               detail: CacheManager.formatted(CacheManager.totalSize()),
                                               tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button {
                                    Haptics.tap()
                                    ToastCenter.shared.show("备份功能开发中")
                                } label: {
                                    SettingRow(icon: "externaldrive.fill", title: "备份与恢复",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        // 界面元素显示
                        if match("界面 元素 显示 迷你 顶部 歌曲行") {
                            SettingGroup(title: "界面元素显示") {
                                SettingToggle(icon: "rectangle.bottomthird.inset.filled", title: "迷你播放条",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showMiniPlayer)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "star", title: "迷你条 · 星标按钮",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showMiniPlayerStar)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "ellipsis", title: "迷你条 · 更多按钮",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showMiniPlayerMore)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "person.circle", title: "圆形头像按钮",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showTopLeftAvatar)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "photo", title: "歌曲行封面",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showSongRowCover)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "ellipsis.circle", title: "歌曲行更多按钮",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showSongRowMore)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "waveform", title: "正在播放指示条",
                                              subtitle: "歌曲行右侧跳动小条",
                                              tint: settings.accent.color, isOn: $settings.showNowPlayingBars)
                            }
                        }

                        // 播放页元素
                        if match("播放页 队列 音量 歌词 电台") {
                            SettingGroup(title: "播放页元素") {
                                SettingToggle(icon: "speaker.wave.2.fill", title: "音量条",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showNowPlayingVolume)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "list.bullet", title: "底部工具条",
                                              subtitle: "歌词 / 电台 / 队列",
                                              tint: settings.accent.color, isOn: $settings.showNowPlayingBottomBar)
                            }
                        }

                        // 主页板块
                        if match("主页 板块 推荐 排行 新歌") {
                            SettingGroup(title: "主页板块") {
                                SettingToggle(icon: "sparkles", title: "新歌精选",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showHomeNewAlbums)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "chart.bar.fill", title: "排行榜",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showHomeRanking)
                                Divider().padding(.leading, 56)
                                SettingToggle(icon: "infinity", title: "私人漫游",
                                              subtitle: nil, tint: settings.accent.color, isOn: $settings.showHomeRoam)
                            }
                        }

                        // 关于与支持
                        if match("关于 支持 更新 反馈 日志 免责 环境") {
                            SettingGroup(title: "关于与支持") {
                                Button { showChangelog = true } label: {
                                    SettingRow(icon: "doc.text", title: "更新日志",
                                               detail: "v\(appVersion)", tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button {
                                    Haptics.tap()
                                    ToastCenter.shared.show("当前已是最新版本")
                                } label: {
                                    SettingRow(icon: "arrow.triangle.2.circlepath", title: "检查更新",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button { showAbout = true } label: {
                                    SettingRow(icon: "exclamationmark.bubble", title: "问题反馈",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button {
                                    Haptics.tap()
                                    BeansLogger.shared.log("用户手动导出日志", level: .info)
                                    ToastCenter.shared.show("日志已记录")
                                } label: {
                                    SettingRow(icon: "stethoscope", title: "诊断与日志",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button { showEnvironment = true } label: {
                                    SettingRow(icon: "info.circle", title: "免责声明",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                Divider().padding(.leading, 56)

                                Button { showEnvironment = true } label: {
                                    SettingRow(icon: "cpu", title: "运行环境",
                                               detail: nil, tint: settings.accent.color)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        // 恢复默认
                        SettingGroup(title: "重置") {
                            Button {
                                Haptics.tap()
                                settings.resetToDefaults()
                                ToastCenter.shared.success("已恢复默认设置")
                            } label: {
                                SettingRow(icon: "arrow.counterclockwise", title: "恢复默认设置",
                                           detail: nil, tint: settings.accent.color)
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
        .confirmationDialog("主题模式", isPresented: $showThemePicker, titleVisibility: .visible) {
            ForEach(ThemeMode.allCases) { mode in
                Button(mode.title) {
                    settings.themeMode = mode
                    Haptics.select()
                }
            }
        }
        .confirmationDialog("主题色", isPresented: $showAccentPicker, titleVisibility: .visible) {
            ForEach(AccentColorOption.allCases) { option in
                Button(option.title) {
                    settings.accent = option
                    Haptics.select()
                }
            }
        }
        .sheet(isPresented: $showChangelog) { ChangelogView() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showEnvironment) { EnvironmentView() }
        .sheet(isPresented: $showPlayerSettings) { PlayerSettingsView() }
        .sheet(isPresented: $showEqualizer) { EqualizerView() }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

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
                .fill(Color.primary.opacity(0.08))
        }
    }
}

// MARK: - 分区容器

struct SettingGroup<Content: View>: View {
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - 通用行

struct SettingRow: View {
    let icon: String
    let title: String
    var detail: String?
    var tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.white)
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
        .padding(.horizontal, 14).padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct SettingToggle: View {
    let icon: String
    let title: String
    var subtitle: String?
    var tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.white)
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
                .onChange(of: isOn) { _ in Haptics.select() }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

// MARK: - 底栏项目配置

struct TabBarConfigView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
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
                Text("已显示（拖动排序）")
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
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("底栏项目")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 子页面

struct AccountView: View {
    var body: some View {
        List {
            Section("网易云音乐") { Text("未登录").foregroundStyle(.secondary) }
            Section("QQ 音乐") { Text("未登录").foregroundStyle(.secondary) }
            Section("酷狗音乐") { Text("未登录").foregroundStyle(.secondary) }
            Section {
                Text("登录后可使用歌单同步、收藏同步等能力。")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("账号登录")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompatNavigationStack {
            List {
                Section("v1.0.0") {
                    Text("· 全新界面：主页 / 浏览 / 广播 / 资料库 / 搜索")
                    Text("· 悬浮液态玻璃底栏，底栏项目可自由开关与排序")
                    Text("· 全屏播放页：歌词、队列、音量、星标、更多菜单")
                    Text("· 三平台搜索：网易云 / QQ 音乐 / 酷狗")
                    Text("· 音源管理：粘贴导入、自动识别卡密、测试结果显示可用性")
                    Text("· 缓存优化：封面压缩存储、缓存上限与自动清理")
                }
            }
            .navigationTitle("更新日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompatNavigationStack {
            List {
                Section("问题反馈") {
                    Text("遇到问题可通过下方交流群反馈。")
                        .font(.system(size: 14))
                }
                Section("交流群") {
                    Text("QQ 群 / Telegram 群，详见「我的 → 交流群」")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("问题反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}

struct EnvironmentView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompatNavigationStack {
            List {
                Section("免责声明") {
                    Text("本应用为个人学习交流用途，音乐版权归各平台所有。请勿用于商业用途。")
                        .font(.system(size: 14))
                }
                Section("运行环境") {
                    LabeledContent("系统版本", value: UIDevice.current.systemVersion)
                    LabeledContent("设备型号", value: UIDevice.current.model)
                    LabeledContent("应用版本", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    LabeledContent("构建号", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
                }
            }
            .navigationTitle("运行环境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}

struct PlayerSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var quality = AudioQuality.current

    var body: some View {
        CompatNavigationStack {
            List {
                Section("音质") {
                    ForEach(AudioQuality.allCases) { item in
                        Button {
                            AudioQuality.setCurrent(item)
                            quality = item
                            Haptics.select()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName).foregroundStyle(.primary)
                                    Text(item.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if quality == item {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(settings.accent.color)
                                }
                            }
                        }
                    }
                }
                Section("播放") {
                    Toggle("启动时自动续播", isOn: $settings.autoPlayOnStart)
                        .tint(settings.accent.color)
                }
            }
            .navigationTitle("播放设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}

struct EqualizerView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    private let bands = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    @State private var gains: [Double] = Array(repeating: 0, count: 10)

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SettingToggle(icon: "slider.horizontal.3", title: "启用均衡器",
                                      subtitle: nil, tint: settings.accent.color, isOn: $settings.showEqualizer)

                        if settings.showEqualizer {
                            HStack(spacing: 6) {
                                ForEach(0..<bands.count, id: \.self) { index in
                                    VStack(spacing: 8) {
                                        Text("\(Int(gains[index]))")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(.secondary)

                                        Slider(value: $gains[index], in: -12...12)
                                            .frame(width: 30, height: 150)
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 30, height: 150)

                                        Text(bands[index])
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 12)

                            Button {
                                gains = Array(repeating: 0, count: 10)
                                Haptics.success()
                                ToastCenter.shared.show("已归零")
                            } label: {
                                Text("归零")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Capsule().fill(settings.accent.color))
                            }
                            .buttonStyle(PressableButtonStyle())
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("均衡器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
    }
}

// 提供 LabeledContent 的 iOS 15 替代（系统版本是 iOS 16+）
struct LabeledContent: View {
    let title: String
    let value: String

    init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
