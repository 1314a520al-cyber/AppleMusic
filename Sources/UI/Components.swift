//
//  Components.swift
//  AppleMusic
//
//  iOS 15 兼容基础组件层。
//  所有 iOS 16+ 专属 API 都在这里用 #available 做了降级封装，
//  其余文件只调用这些封装，保证部署目标 15.0 也能编译。
//

import SwiftUI
import UIKit

// MARK: - 毛玻璃底层

struct VisualEffectBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// 全屏氛围背景：随封面/主题变化的大面积柔和渐变
struct AmbienceBackdrop: View {
    var tint: Color = .accentColor

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            LinearGradient(
                colors: [tint.opacity(0.20), tint.opacity(0.06), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .blur(radius: 40)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 按压动效

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var opacity: Double = 1.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity * 0.92 : opacity)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - iOS 15 兼容包装

struct CompatNavigationStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }.navigationViewStyle(.stack)
        }
    }
}

struct ScrollBackgroundHidden: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

struct ScrollIndicatorsHidden: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.scrollIndicators(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func compatScrollBackgroundHidden() -> some View { modifier(ScrollBackgroundHidden()) }
    func compatScrollIndicatorsHidden() -> some View { modifier(ScrollIndicatorsHidden()) }
}

// MARK: - 播放/暂停图标

struct PlayPauseIcon: View {
    let isPlaying: Bool
    var size: CGFloat = 22

    private var progress: CGFloat { isPlaying ? 1 : 0 }

    var body: some View {
        ZStack {
            Image(systemName: "play.fill")
                .font(.system(size: size, weight: .semibold))
                .opacity(1 - progress)
                .scaleEffect(1 - progress * 0.18)
                .offset(x: progress * 5)

            HStack(spacing: max(3, size * 0.18)) {
                RoundedRectangle(cornerRadius: max(1.5, size * 0.08), style: .continuous)
                    .frame(width: max(4, size * 0.24), height: size * 0.86)
                RoundedRectangle(cornerRadius: max(1.5, size * 0.08), style: .continuous)
                    .frame(width: max(4, size * 0.24), height: size * 0.86)
            }
            .opacity(progress)
            .scaleEffect(0.82 + progress * 0.18)
            .offset(x: (1 - progress) * -5)
        }
        .frame(width: size + 6, height: size + 6)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isPlaying)
    }
}

// MARK: - 正在播放指示器

struct NowPlayingBars: View {
    var color: Color = .accentColor
    var animated: Bool = true

    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Capsule().fill(color).frame(width: 2.5, height: height(for: index))
            }
        }
        .frame(height: 14, alignment: .bottom)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { phase = 1 }
        }
    }

    private func height(for index: Int) -> CGFloat {
        let base: [CGFloat] = [8, 14, 10]
        let swing: [CGFloat] = [4, -6, 5]
        return max(3, base[index] + swing[index] * phase)
    }
}

// MARK: - 空态 / 加载态

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .thin))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            if let message {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 48)
    }
}

struct LoadingStateView: View {
    var text: String = "载入中…"

    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(text).font(.system(size: 13)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 标题

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GroupCaption: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 6)
    }
}

// MARK: - 封面

struct CoverArtView: View {
    let url: URL?
    var size: CGFloat = 52
    var cornerRadius: CGFloat = 6

    var body: some View {
        CachedAsyncImage(url: url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                LinearGradient(
                    colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.34, weight: .light))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
        }
    }
}

// MARK: - 分隔线

struct InsetDivider: View {
    var leading: CGFloat = 68

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.10))
            .frame(height: 0.5)
            .padding(.leading, leading)
    }
}
