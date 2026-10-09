//
//  FloatingTabBar.swift
//  AppleMusic
//
//  底部导航栏。
//
//  默认与参考图一致：贴底、图标在上文字在下、选中项变主题色。
//  可在设置里切换为「悬浮液态玻璃」形态。
//

import SwiftUI
import UIKit

struct FloatingTabBar: View {

    @Binding var selection: TabItem
    var miniPlayerVisible: Bool = false

    @EnvironmentObject private var settings: AppSettings
    @Namespace private var indicatorNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(settings.activeTabs) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, settings.floatingTabBar ? 6 : 0)
        .padding(.vertical, settings.floatingTabBar ? 6 : 8)
        .background { barBackground }
        .padding(.horizontal, settings.floatingTabBar ? 14 : 0)
        .padding(.bottom, settings.floatingTabBar ? (miniPlayerVisible ? 8 : 14) : 0)
    }

    private func tabButton(_ tab: TabItem) -> some View {
        let isSelected = selection == tab

        return Button {
            guard selection != tab else { return }
            Haptics.select()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 24)

                if settings.showTabLabels {
                    Text(tab.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(isSelected ? settings.accent.color : Color.primary.opacity(0.62))
            .frame(maxWidth: .infinity)
            .frame(height: settings.floatingTabBar ? 48 : 44)
            .background {
                if isSelected && settings.floatingTabBar {
                    Capsule(style: .continuous)
                        .fill(settings.accent.color.opacity(0.16))
                        .matchedGeometryEffect(id: "tabIndicator", in: indicatorNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
    }

    /// 悬浮模式用胶囊毛玻璃；贴底模式用一条磨砂栏 + 顶部细线
    @ViewBuilder
    private var barBackground: some View {
        if settings.floatingTabBar {
            Capsule(style: .continuous)
                .fill(.clear)
                .background {
                    VisualEffectBlurView(style: .systemUltraThinMaterial)
                        .clipShape(Capsule(style: .continuous))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.7)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.16), .white.opacity(0.03), .black.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.28), radius: 20, y: 8)
        } else {
            Rectangle()
                .fill(.clear)
                .background { VisualEffectBlurView(style: .systemThinMaterial) }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 0.5)
                }
        }
    }
}
