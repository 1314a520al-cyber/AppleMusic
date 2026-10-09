//
//  CacheManager.swift
//  AppleMusic
//
//  缓存统计与清理。对应「我的 → 清除缓存」。
//

import Foundation
import UIKit
import SwiftUI

struct CacheCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let size: Int64
    let color: Color
}

enum CacheManager {

    static func categories() -> [CacheCategory] {
        let fm = FileManager.default
        let networkCache = Int64(URLCache.shared.currentDiskUsage)
        let coverCache = ImageDiskCache.totalSize()
        let tempFiles = directorySize(fm.temporaryDirectory)
        let downloads = directorySize(in: .documentDirectory, subpath: "Downloads")
        let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
        let totalCaches = cachesDir.map { directorySize($0) } ?? 0
        let otherCache = max(0, totalCaches - coverCache)

        return [
            CacheCategory(name: "网络缓存", icon: "network", size: networkCache, color: .blue),
            CacheCategory(name: "封面缓存", icon: "photo", size: coverCache, color: .pink),
            CacheCategory(name: "临时文件", icon: "tray", size: tempFiles, color: .gray),
            CacheCategory(name: "其他缓存", icon: "square.stack", size: otherCache, color: .teal),
            CacheCategory(name: "已下载歌曲", icon: "arrow.down.circle.fill", size: downloads, color: .green)
        ]
    }

    static func totalSize() -> Int64 {
        categories()
            .filter { $0.name != "已下载歌曲" }
            .reduce(0) { $0 + $1.size }
    }

    static func clearAll() {
        URLCache.shared.removeAllCachedResponses()
        ImageMemoryCache.shared.removeAll()
        ImageDiskCache.removeAll()
        PlayerManager.clearURLCache()

        let fm = FileManager.default
        if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            clearContents(of: caches)
        }
        clearContents(of: fm.temporaryDirectory)
    }

    static func clearCategory(_ name: String) {
        let fm = FileManager.default
        switch name {
        case "网络缓存":
            URLCache.shared.removeAllCachedResponses()
            PlayerManager.clearURLCache()
        case "封面缓存":
            ImageMemoryCache.shared.removeAll()
            ImageDiskCache.removeAll()
        case "临时文件":
            clearContents(of: fm.temporaryDirectory)
        case "其他缓存":
            if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
                clearContents(of: caches)
                ImageMemoryCache.shared.removeAll()
            }
        default:
            break
        }
    }

    static func formatted(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: max(0, bytes))
    }

    // MARK: - Private

    private static func directorySize(in domain: FileManager.SearchPathDirectory, subpath: String) -> Int64 {
        guard let base = FileManager.default.urls(for: domain, in: .userDomainMask).first else { return 0 }
        return directorySize(base.appendingPathComponent(subpath))
    }

    private static func directorySize(_ directory: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            if values?.isRegularFile == true {
                total += Int64(values?.fileSize ?? 0)
            }
        }
        return total
    }

    private static func clearContents(of directory: URL, keep: [String] = []) {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for item in items {
            if keep.contains(item.lastPathComponent) { continue }
            try? fm.removeItem(at: item)
        }
    }
}
