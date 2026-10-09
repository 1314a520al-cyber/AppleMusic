//
//  FloatingTabBar.swift
//  AppleMusic
//
//  悬浮液态玻璃底部导航栏。
//
//  用 UIVisualEffectView 毛玻璃 + 渐变高光 + 描边 + 阴影，
//  在 iOS 15 上也能呈现「液态玻璃」观感。
//
//  显示哪些项目、是否带文字、是否悬浮，全部由 AppSettings 控制。
//

import SwiftUI
import UIKit

struct FloatingTabBar: View {

    @Binding var selection: TabItem
    var miniPlayerVisible: Bool = false

    @EnvironmentObject private var settings: AppSettings
    @Namespace private var indicatorNamespace

    private var bottomPadding: CGFloat { miniPlayerVisible ? 8 : 14 }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(settings.activeTabs) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background { glassBackground }
        .padding(.horizontal, settings.floatingTabBar ? 14 : 0)
        .padding(.bottom, settings.floatingTabBar ? bottomPadding : 0)
    }

    private func tabButton(_ tab: TabItem) -> some View {
        let isSelected = selection == tab

        return Button {
            guard selection != tab else { return }
            Haptics.select()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 23)

                if settings.showTabLabels {
                    Text(tab.title)
                        .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .foregroundStyle(isSelected ? settings.accent.color : Color.primary.opacity(0.60))
            .frame(maxWidth: .infinity)
            .frame(height: settings.showTabLabels ? 50 : 42)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(settings.accent.color.opacity(0.16))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(settings.accent.color.opacity(0.18), lineWidth: 0.6)
                        }
                        .matchedGeometryEffect(id: "tabIndicator", in: indicatorNamespace)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
    }

    /// 玻璃底：悬浮时是圆角胶囊，关闭「悬浮」后退化为一条贴底磨砂栏
    @ViewBuilder
    private var glassBackground: some View {
        if settings.floatingTabBar {
            Capsule(style: .continuous)
                .fill(.clear)
                .background {
                    VisualEffectBlurView(style: .systemUltraThinMaterial)
                        .clipShape(Capsule(style: .continuous))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.20), lineWidth: 0.7)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.18), .white.opacity(0.04), .black.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.28), radius: 20, y: 8)
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        } else {
            Rectangle()
                .fill(.clear)
                .background { VisualEffectBlurView(style: .systemUltraThinMaterial) }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 0.5)
                }
        }
    }
}
