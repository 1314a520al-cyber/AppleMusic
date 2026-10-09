//
//  ToastCenter.swift
//  AppleMusic
//
//  轻量提示条：底部浮出胶囊，2 秒自动消失。
//

import SwiftUI
import Combine

final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let icon: String?
        let style: Style

        enum Style { case normal, success, error }

        static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
    }

    @Published private(set) var current: Toast?

    private var dismissWork: DispatchWorkItem?
    private init() {}

    func show(_ text: String, icon: String? = nil, style: Toast.Style = .normal) {
        let toast = Toast(text: text, icon: icon, style: style)
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                self.current = toast
            }
            self.dismissWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                withAnimation(.easeOut(duration: 0.22)) { self?.current = nil }
            }
            self.dismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
        }
    }

    func success(_ text: String) { show(text, icon: "checkmark.circle.fill", style: .success) }
    func error(_ text: String) { show(text, icon: "exclamationmark.triangle.fill", style: .error) }
}

struct ToastHostView: View {
    @ObservedObject var center: ToastCenter

    var body: some View {
        VStack {
            Spacer()
            if let toast = center.current {
                HStack(spacing: 8) {
                    if let icon = toast.icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(iconColor(toast.style))
                    }
                    Text(toast.text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(.clear)
                        .background {
                            VisualEffectBlurView(style: .systemThickMaterial)
                                .clipShape(Capsule())
                        }
                        .overlay { Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.6) }
                }
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
                .padding(.horizontal, 40)
                .padding(.bottom, 130)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
    }

    private func iconColor(_ style: ToastCenter.Toast.Style) -> Color {
        switch style {
        case .normal: return .accentColor
        case .success: return .green
        case .error: return .orange
        }
    }
}
