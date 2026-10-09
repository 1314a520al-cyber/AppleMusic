//
//  MineView.swift
//  AppleMusic
//
//  「我的」：音源管理、清除缓存、音质、赞赏、交流群、设置。
//  所有条目都受 AppSettings 开关控制，可在设置页自由开关。
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
    @State private var cacheSizeText = "计算中…"
    @State private var qualitySelection = AudioQuality.current

    var body: some View {
        CompatNavigationStack {
            ZStack {
                AmbienceBackdrop(tint: .gray)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("我的")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // 音乐设置组
                        VStack(spacing: 0) {
                            ForEach(Array(settingsRows.enumerated()), id: \.offset) { index, row in
                                Button {
                                    Haptics.tap()
                                    row.action()
                                } label: {
                                    settingRow(icon: row.icon, tint: row.tint,
                                               title: row.title, detail: row.detail)
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))

                                if index < settingsRows.count - 1 {
                                    InsetDivider(leading: 60)
                                }
                            }
                        }
                        .background { RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)) }
                        .padding(.horizontal, 16)

                        // 支持与社群
                        if settings.showRewardEntry || settings.showGroupEntry {
                            VStack(spacing: 0) {
                                if settings.showRewardEntry {
                                    Button { Haptics.tap(); showReward = true } label: {
                                        settingRow(icon: "heart.circle.fill", tint: .red,
                                                   title: "赞赏支持", detail: nil)
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                }

                                if settings.showRewardEntry && settings.showGroupEntry {
                                    InsetDivider(leading: 60)
                                }

                                if settings.showGroupEntry {
                                    Button { Haptics.tap(); showGroups = true } label: {
                                        settingRow(icon: "person.3.fill", tint: .green,
                                                   title: "交流群", detail: nil)
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                                }
                            }
                            .background { RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)) }
                            .padding(.horizontal, 16)
                        }

                        // 存储
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "存储").padding(.horizontal, 20)
                            HStack(spacing: 14) {
                                Image(systemName: "internaldrive.fill")
                                    .font(.system(size: 16)).foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.gray))
                                Text("已下载歌曲").font(.system(size: 16))
                                Spacer(minLength: 0)
                                Text(CacheManager.formatted(downloads.totalSize()))
                                    .font(.system(size: 14)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 11)
                            .background { RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)) }
                            .padding(.horizontal, 16)
                        }

                        // 关于
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle(text: "关于").padding(.horizontal, 20)
                            Text("AppleMusic · 版本 \(appVersion)")
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                            Text("本应用为个人学习交流用途，音乐版权归各平台所有。")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                                .padding(.horizontal, 20).padding(.top, 2)
                        }

                        Spacer(minLength: 150)
                    }
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationBarHidden(true)
        }
        .onAppear { refreshCacheSize() }
        .sheet(isPresented: $showSourceManager) {
            MusicSourceManagerView()
        }
        .sheet(isPresented: $showCacheManager) {
            CacheManagerView()
        }
        .sheet(isPresented: $showReward) {
            RewardView()
        }
        .sheet(isPresented: $showGroups) {
            GroupView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .confirmationDialog("选择音质", isPresented: $showQualityPicker, titleVisibility: .visible) {
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

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// 设置行模型：把「是否显示 / 图标 / 文案 / 动作」集中成数据，
    /// 避免在 ViewBuilder 里写命令式语句（SwiftUI 不允许）。
    private struct SettingsRow {
        let icon: String
        let tint: Color
        let title: String
        let detail: String?
        let action: () -> Void
    }

    private var settingsRows: [SettingsRow] {
        var rows: [SettingsRow] = []

        if settings.showSourceEntry {
            rows.append(SettingsRow(
                icon: "antenna.radiowaves.left.and.right", tint: .blue,
                title: "音源管理", detail: "\(sourceStore.sources.count) 个",
                action: { showSourceManager = true }
            ))
        }

        if settings.showCacheEntry {
            rows.append(SettingsRow(
                icon: "trash.fill", tint: .orange,
                title: "清除缓存", detail: cacheSizeText,
                action: { showCacheManager = true }
            ))
        }

        if settings.showQualityEntry {
            rows.append(SettingsRow(
                icon: "waveform", tint: .purple,
                title: "音质", detail: qualitySelection.displayName,
                action: { showQualityPicker = true }
            ))
        }

        rows.append(SettingsRow(
            icon: "gearshape.fill", tint: .gray,
            title: "设置", detail: nil,
            action: { showSettings = true }
        ))

        return rows
    }

    private func settingRow(icon: String, tint: Color, title: String, detail: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16)).foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))
            Text(title).font(.system(size: 16)).foregroundStyle(.primary)
            Spacer(minLength: 0)
            if let detail {
                Text(detail).font(.system(size: 14)).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func refreshCacheSize() {
        cacheSizeText = CacheManager.formatted(CacheManager.totalSize())
    }
}
