//
//  AudioQuality.swift
//  AppleMusic
//

import Foundation

enum AudioQuality: String, CaseIterable, Identifiable {
    case low
    case standard
    case higher
    case exhigh
    case lossless
    case hires

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:      return "省流"
        case .standard: return "标准"
        case .higher:   return "较高"
        case .exhigh:   return "极高"
        case .lossless: return "无损"
        case .hires:    return "高解析度"
        }
    }

    var detail: String {
        switch self {
        case .low:      return "64 kbps"
        case .standard: return "128 kbps"
        case .higher:   return "192 kbps"
        case .exhigh:   return "320 kbps"
        case .lossless: return "无损音质"
        case .hires:    return "Hi-Res 无损"
        }
    }

    var neteaseLevel: String {
        switch self {
        case .low, .standard: return "standard"
        case .higher:         return "higher"
        case .exhigh:         return "exhigh"
        case .lossless:       return "lossless"
        case .hires:          return "hires"
        }
    }

    var sourceQuality: String {
        switch self {
        case .low, .standard, .higher: return "128k"
        case .exhigh, .lossless, .hires: return "320k"
        }
    }

    static var current: AudioQuality {
        let raw = UserDefaults.standard.string(forKey: "appleMusic.audioQuality") ?? ""
        return AudioQuality(rawValue: raw) ?? .exhigh
    }

    static func setCurrent(_ quality: AudioQuality) {
        UserDefaults.standard.set(quality.rawValue, forKey: "appleMusic.audioQuality")
    }
}
