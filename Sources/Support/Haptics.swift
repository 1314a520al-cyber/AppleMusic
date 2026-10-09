//
//  Haptics.swift
//  AppleMusic
//
//  触感反馈。受设置 appleMusic.hapticEnabled 控制。
//

import UIKit

enum Haptics {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    private static var enabled: Bool {
        UserDefaults.standard.bool(forKey: "appleMusic.hapticEnabled")
    }

    static func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        selection.prepare()
    }

    static func tap() { if enabled { lightImpact.impactOccurred() } }
    static func light() { if enabled { lightImpact.impactOccurred() } }
    static func medium() { if enabled { mediumImpact.impactOccurred() } }
    static func heavy() { if enabled { heavyImpact.impactOccurred() } }
    static func success() { if enabled { notification.notificationOccurred(.success) } }
    static func warning() { if enabled { notification.notificationOccurred(.warning) } }
    static func error() { if enabled { notification.notificationOccurred(.error) } }
    static func select() { if enabled { selection.selectionChanged() } }
}
