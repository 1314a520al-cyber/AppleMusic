//
//  SettingsView.swift
//  AppleMusic
//
//  设置页：所有功能开关，可自由开/关。
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompatNavigationStack {
            List {
                // 外观与交互
                Section {
                    Toggle(isOn: $settings.hapticEnabled) {
                        label(icon: "hand.tap.fill", tint: .blue, title: "触感反馈")
                    }
                    Toggle(isOn: $settings.showMiniPlayer) {
                        label(icon: "rectangle.bottomthird.inset.filled", tint: .indigo, title: "显示迷你播放条")
                    }
                    Toggle(isOn: $settings.showTabLabels) {
                        label(icon: "textformat", tint: .teal, title: "底栏显示文字")
                    }
                    Toggle(isOn: $settings.showNowPlayingBars) {
                        label(icon: "waveform", tint: .pink, title: "正在播放指示条")
                    }
                    Toggle(isOn: $settings.showLyricsInPlayer) {
                        label(icon: "quote.bubble.fill", tint: .purple, title: "播放页显示歌词入口")
                    }
                } header: {
                    Text("外观与交互")
                }

                // 播放
                Section {
                    Toggle(isOn: $settings.autoPlayOnStart) {
                        label(icon: "play.circle.fill", tint: .green, title: "启动时自动续播")
                    }
                } header: {
                    Text("播放")
                }

                // 我的页面入口
                Section {
                    Toggle(isOn: $settings.showSourceEntry) {
                        label(icon: "antenna.radiowaves.left.and.right", tint: .blue, title: "音源管理入口")
                    }
                    Toggle(isOn: $settings.showCacheEntry) {
                        label(icon: "trash.fill", tint: .orange, title: "清除缓存入口")
                    }
                    Toggle(isOn: $settings.showQualityEntry) {
                        label(icon: "waveform", tint: .purple, title: "音质入口")
                    }
                    Toggle(isOn: $settings.showRewardEntry) {
                        label(icon: "heart.circle.fill", tint: .red, title: "赞赏支持入口")
                    }
                    Toggle(isOn: $settings.showGroupEntry) {
                        label(icon: "person.3.fill", tint: .green, title: "交流群入口")
                    }
                    Toggle(isOn: $settings.showDownloadsEntry) {
                        label(icon: "arrow.down.circle.fill", tint: .mint, title: "资料库下载入口")
                    }
                } header: {
                    Text("我的页面入口")
                } footer: {
                    Text("关闭后对应入口会从「我的」页隐藏，功能本身不受影响。")
                }

                // 恢复默认
                Section {
                    Button {
                        Haptics.tap()
                        settings.resetToDefaults()
                        ToastCenter.shared.success("已恢复默认设置")
                    } label: {
                        HStack {
                            Spacer()
                            Text("恢复默认设置").foregroundStyle(Color.accentColor)
                            Spacer()
                        }
                    }
                }
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

    private func label(icon: String, tint: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))
            Text(title).font(.system(size: 16))
        }
    }
}
