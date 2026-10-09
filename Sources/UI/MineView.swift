//
//  MineView.swift
//  AppleMusic
//
//  「我的」。
//
//  结构（对照参考图）：
//    顶部：彩色圆形头像 + 昵称 + ID 胶囊（带复制图标）
//    听歌时长大卡（背景图 + 红色时钟图标）
//    音乐收藏卡
//    交流群卡（可展开：QQ 群 / TG 通知群 / TG 交流群）
//    各项入口（可在设置里自由开关）
//

import SwiftUI

struct MineView: View {

    @ObservedObject private var sourceStore = MusicSourceStore.shared
    @ObservedObject private var downloads = DownloadStore.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var showSourceManager = false
    @State private var showCacheManager = false
    @State private var showQualityPicker = false
    @State private var showReward = false
    @State private var showGroups = false
    @State private var showSettings = false
    @State private var showDownloads = false
    @State private var showFavorites = false
    @State private var cacheSizeText = "计算中…"
    @State private var qualitySelection = AudioQuality.current
    @State private var groupExpanded = false
    @State private var userId = "206137"

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        profileHeader

                        listeningCard

                        // 音乐收藏
                        cardSection {
                            Button { Haptics.tap(); showFavorites = true } label: {
                                rowLabel(icon: "star.fill", tint: settings.accent.color,
                                         title: "音乐收藏", detail: "\(favoritesCount()) 首")
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                        }

                        // 功能入口
                        if !entryRows.isEmpty {
                            cardSection {
                                ForEach(Array(entryRows.enumerated()), id: \.offset) { index, row in
                                    Button {
                                        Haptics.tap()
                                        row.action()
                                    } label: {
                                        rowLabel(icon: row.icon, tint: settings.accent.color,
                                                 title: row.title, detail: row.detail)
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                                    if index < entryRows.count - 1 {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                        }

                        // 交流群
                        if settings.showGroupEntry {
                            cardSection {
                                Button {
                                    Haptics.tap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        groupExpanded.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 15)).foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                .fill(settings.accent.color))
                                        Text("交流群").font(.system(size: 16)).foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: groupExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                                if groupExpanded {
                                    Divider().padding(.leading, 56)
                                    groupRow(icon: "person.3", title: "QQ 群", urlString: qqGroupURL)
                                    Divider().padding(.leading, 56)
                                    groupRow(icon: "bell.fill", title: "TG 通知群", urlString: tgGroupURL)
                                    Divider().padding(.leading, 56)
                                    groupRow(icon: "person.2.fill", title: "TG 交流群", urlString: tgGroupURL)
                                }
                            }
                        }

                        // 赞赏
                        if settings.showRewardEntry {
                            cardSection {
                                Button { Haptics.tap(); showReward = true } label: {
                                    rowLabel(icon: "heart.fill", tint: settings.accent.color,
                                             title: "赞赏支持", detail: nil)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                            }
                        }

                        Spacer(minLength: 170)
                    }
                    .padding(.top, 10)
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationBarHidden(true)
        }
        .onAppear { refreshCacheSize() }
        .sheet(isPresented: $showSourceManager) { MusicSourceManagerView() }
        .sheet(isPresented: $showCacheManager) { CacheManagerView() }
        .sheet(isPresented: $showReward) { RewardView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showFavorites) {
            CompatNavigationStack {
                FavoritesView(showNowPlaying: .constant(false))
            }
        }
        .sheet(isPresented: $showDownloads) {
            CompatNavigationStack {
                DownloadsView(showNowPlaying: .constant(false))
            }
        }
        .confirmationDialog("音质", isPresented: $showQualityPicker, titleVisibility: .visible) {
            ForEach(AudioQuality.allCases) { quality in
                Button("\(quality.displayName)（\(quality.detail)）") {
                    AudioQuality.setCurrent(quality)
                    qualitySelection = quality
                    ToastCenter.shared.show("音质已设为\(quality.displayName)")
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - 顶部资料

    private var profileHeader: some View {
        HStack(spacing: 12) {
            // 彩色环头像
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [settings.accent.color, .orange, settings.accent.color.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 54, height: 54)
                .overlay {
                    Text("L")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(settings.accent.color)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Circle().fill(settings.accent.color))
                        .offset(x: 2, y: 2)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text("Love")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)

                Button {
                    UIPasteboard.general.string = userId
                    Haptics.success()
                    ToastCenter.shared.success("已复制 ID")
                } label: {
                    HStack(spacing: 5) {
                        Text("ID · \(userId)")
                            .font(.system(size: 12))
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            Image(systemName: "waveform")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(settings.accent.color)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 听歌时长卡

    private var listeningCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [settings.accent.color.opacity(0.55), settings.accent.color.opacity(0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            Image(systemName: "music.note.list")
                .font(.system(size: 110))
                .foregroundStyle(.white.opacity(0.10))
                .offset(x: 200, y: -10)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                    Text("听歌时长")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.9))

                Text("\(totalMinutes()) 分钟")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)

                Text("累计播放 \(PlayHistoryStore.shared.songs.count) 首")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - 通用

    private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
            .padding(.horizontal, 16)
    }

    private func rowLabel(icon: String, tint: Color, title: String, detail: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))

            Text(title).font(.system(size: 16)).foregroundStyle(.primary)

            Spacer(minLength: 0)

            if let detail {
                Text(detail).font(.system(size: 14)).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func groupRow(icon: String, title: String, urlString: String) -> some View {
        Button {
            Haptics.tap()
            openURL(urlString)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(settings.accent.color)
                    .frame(width: 28)
                Text(title).font(.system(size: 15)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 14).padding(.trailing, 16).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
    }

    // MARK: - 数据

    private struct EntryRow {
        let icon: String
        let title: String
        let detail: String?
        let action: () -> Void
    }

    private var entryRows: [EntryRow] {
        var rows: [EntryRow] = []

        if settings.showSourceEntry {
            rows.append(EntryRow(icon: "antenna.radiowaves.left.and.right", title: "音源管理",
                                 detail: "\(sourceStore.sources.count) 个",
                                 action: { showSourceManager = true }))
        }
        if settings.showCacheEntry {
            rows.append(EntryRow(icon: "trash.fill", title: "清除缓存",
                                 detail: cacheSizeText,
                                 action: { showCacheManager = true }))
        }
        if settings.showQualityEntry {
            rows.append(EntryRow(icon: "waveform", title: "音质",
                                 detail: qualitySelection.displayName,
                                 action: { showQualityPicker = true }))
        }
        if settings.showDownloadsEntry {
            rows.append(EntryRow(icon: "arrow.down.circle.fill", title: "已下载",
                                 detail: downloads.items.isEmpty ? "暂无" : "\(downloads.items.count) 首",
                                 action: { showDownloads = true }))
        }

        rows.append(EntryRow(icon: "gearshape.fill", title: "设置",
                             detail: nil, action: { showSettings = true }))

        return rows
    }

    private func favoritesCount() -> Int { FavoritesStore.shared.songs.count }

    private func totalMinutes() -> Int {
        let total = PlayHistoryStore.shared.songs.reduce(0.0) { $0 + $1.duration }
        return max(0, Int(total / 60))
    }

    private func refreshCacheSize() {
        cacheSizeText = CacheManager.formatted(CacheManager.totalSize())
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success, let web = URL(string: string) {
                UIApplication.shared.open(web, options: [:], completionHandler: nil)
            }
        }
    }

    private let qqGroupURL = "https://qun.qq.com/universal-share/share?ac=1&authKey=gK79P149V02wF2J8sVuEqs3PK73INLT62KGtb9vys46q0GY4t0SxTDyFqOVbjbuQ&busi_data=eyJncm91cENvZGUiOiI1MjE0NzMyMjIiLCJ0b2tlbiI6Ii9MelJDU1VrQ1BaeEZvOHRySUo4RjVlNWlnb1IySW9JZFBKTFFUaElMdGJQRlJ3eW"
    private let tgGroupURL = "https://t.me/Vxinol"
}
