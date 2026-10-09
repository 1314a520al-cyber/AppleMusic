//
//  PlatformPreferenceStore.swift
//  AppleMusic
//
//  当前音乐平台偏好（对应界面右上角的「音源切换」下拉）。
//

import Foundation
import SwiftUI

enum MusicPlatform: String, CaseIterable, Identifiable {
    case netease
    case qq
    case kugou

    var id: String { rawValue }

    var title: String {
        switch self {
        case .netease: return "网易云音乐"
        case .qq:      return "QQ 音乐"
        case .kugou:   return "酷狗音乐"
        }
    }

    /// 对应 Song.source
    var songSource: SongSource {
        switch self {
        case .netease: return .netease
        case .qq:      return .qq
        case .kugou:   return .kugou
        }
    }

    var icon: String {
        switch self {
        case .netease: return "music.note"
        case .qq:      return "music.note.list"
        case .kugou:   return "music.quarternote.3"
        }
    }
}

final class PlatformPreferenceStore: ObservableObject {
    static let shared = PlatformPreferenceStore()

    @Published var platform: MusicPlatform {
        didSet {
            UserDefaults.standard.set(platform.rawValue, forKey: "appleMusic.platform")
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "appleMusic.platform") ?? ""
        platform = MusicPlatform(rawValue: raw) ?? .netease
    }
}
