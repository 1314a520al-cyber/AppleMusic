//
//  FloatingTabBar.swift
//  AppleMusic
//
//  悬浮液态玻璃底部导航栏。
//  用 UIVisualEffectView 毛玻璃 + 渐变高光 + 描边 + 阴影，
//  在 iOS 15 上还原 iOS 26「液态玻璃」观感。
//

import SwiftUI
import UIKit

enum TabItem: String, CaseIterable, Identifiable {
    case home
    case radio
    case search
    case library
    case mine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:    return "主页"
        case .radio:   return "广播"
        case .search:  return "搜索"
        case .library: return "资料库"
        case .mine:    return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house"
        case .radio:   return "dot.radiowaves.left.and.right"
        case .search:  return "magnifyingglass"
        case .library: return "square.stack"
        case .mine:    return "person.crop.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:    return "house.fill"
        case .radio:   return "dot.radiowaves.left.and.right"
        case .search:  return "magnifyingglass"
        case .library: return "square.stack.fill"
        case .mine:    return "person.crop.circle.fill"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: TabItem
    var miniPlayerVisible: Bool = false

    @EnvironmentObject private var settings: AppSettings
    @Namespace private var indicatorNamespace

    private var bottomPadding: CGFloat { miniPlayerVisible ? 8 : 14 }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TabItem.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background { glassBackground }
        .padding(.horizontal, 14)
        .padding(.bottom, bottomPadding)
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
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 22)

                if settings.showTabLabels {
                    Text(tab.title)
                        .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.62))
            .frame(maxWidth: .infinity)
            .frame(height: settings.showTabLabels ? 50 : 40)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(0.13))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.16), lineWidth: 0.6)
                        }
                        .matchedGeometryEffect(id: "tabIndicator", in: indicatorNamespace)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
    }

    private var glassBackground: some View {
        Capsule(style: .continuous)
            .fill(.clear)
            .background {
                VisualEffectBlurView(style: .systemUltraThinMaterial)
                    .clipShape(Capsule(style: .continuous))
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 0.7)
            }
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.04), .black.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.16), radius: 20, y: 8)
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}
