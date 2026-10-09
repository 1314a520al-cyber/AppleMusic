//
//  CachedAsyncImage.swift
//  AppleMusic
//
//  带两级缓存的异步图片加载。
//
//  —— 省空间/省内存的关键设计 ——
//  1. 磁盘里只保存「降采样后的小图」（长边不超过 maxStoredDimension），
//     不再把原始大图整张写盘。一张 3000×3000 的原图会让磁盘缓存瞬间涨到几 MB，
//     几十张就上百 MB，这是之前缓存暴涨的主因。
//  2. 一个 URL 只对应一个文件（按 URL 做 hash 命名），不会因不同显示尺寸重复存。
//  3. 磁盘缓存有总容量上限，写入后若超额，按「最久未访问」清理。
//  4. 内存缓存用 NSCache，系统内存紧张时自动回收。
//

import SwiftUI
import UIKit
import ImageIO
import CommonCrypto

// MARK: - 内存缓存

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 120
        cache.totalCostLimit = 32 * 1024 * 1024   // 32MB 上限
    }

    func image(for key: String) -> UIImage? { cache.object(forKey: key as NSString) }

    func store(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func removeAll() { cache.removeAllObjects() }
}

// MARK: - 磁盘缓存（带 LRU 上限）

enum ImageDiskCache {

    private static let folderName = "AMImageCache"
    /// 磁盘缓存总上限：60MB。超出后清最久未访问的文件。
    private static let maxTotalBytes: Int64 = 60 * 1024 * 1024
    /// 存盘时图片长边上限（像素）。超过这个尺寸会先压缩再存。
    static let maxStoredDimension: CGFloat = 400

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 用 URL 的 MD5 做文件名：同一 URL 只对应一个文件，且文件名长度固定
    private static func fileName(for key: String) -> String {
        guard let data = key.data(using: .utf8) else { return "unknown" }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { raw in
            _ = CC_MD5(raw.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func fileURL(for key: String) -> URL? {
        guard let directory else { return nil }
        return directory.appendingPathComponent(fileName(for: key))
    }

    static func data(for key: String) -> Data? {
        guard let url = fileURL(for: key) else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        // 更新访问时间，供 LRU 使用
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
        return try? Data(contentsOf: url)
    }

    /// 存盘：只存压缩后的小图数据
    static func store(_ data: Data, for key: String) {
        guard let url = fileURL(for: key) else { return }
        try? data.write(to: url, options: .atomic)
        trimIfNeeded()
    }

    static func removeAll() {
        guard let directory else { return }
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for item in items { try? fm.removeItem(at: item) }
        }
    }

    static func totalSize() -> Int64 {
        guard let directory else { return 0 }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for item in items {
            total += Int64((try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    /// 超出上限时按最久未访问清理，直到降到上限的 80%
    private static func trimIfNeeded() {
        guard let directory else { return }
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys) else { return }

        var entries: [(url: URL, size: Int64, date: Date)] = []
        var total: Int64 = 0
        for item in items {
            let values = try? item.resourceValues(forKeys: Set(keys))
            let size = Int64(values?.fileSize ?? 0)
            let date = values?.contentModificationDate ?? .distantPast
            entries.append((item, size, date))
            total += size
        }

        guard total > maxTotalBytes else { return }
        let target = Int64(Double(maxTotalBytes) * 0.8)
        // 最旧的先删
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            if total <= target { break }
            try? fm.removeItem(at: entry.url)
            total -= entry.size
        }
    }
}

// MARK: - 降采样与压缩

enum ImageDownsampler {

    /// 按目标像素尺寸降采样解码，避免把整张大图展开进内存
    static func downsample(data: Data, to pointSize: CGFloat, scale: CGFloat) -> UIImage? {
        let maxDimension = max(pointSize * scale, 1)
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// 把原图数据压缩成「长边不超过 maxDimension 的 JPEG」，
    /// 用于写入磁盘缓存 —— 这是把缓存从几百 MB 压下来的关键。
    static func compressedForStorage(data: Data, maxDimension: CGFloat = ImageDiskCache.maxStoredDimension) -> Data? {
        guard let image = downsample(data: data, to: maxDimension / UIScreen.main.scale, scale: UIScreen.main.scale) else {
            return nil
        }
        return image.jpegData(compressionQuality: 0.72)
    }
}

// MARK: - 加载器

final class ImageLoader {
    static let shared = ImageLoader()

    private let semaphore = DispatchSemaphore(value: 4)
    private let session: URLSession
    /// 同一 URL 正在下载时，避免重复发起请求
    private var inFlight = Set<String>()
    private let lock = NSLock()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        // 图片走我们自己的磁盘缓存，URL 层不再重复缓存一份
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        session = URLSession(configuration: config)
    }

    func load(url: URL, targetSize: CGFloat, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString
        let scale = UIScreen.main.scale
        let cacheKey = "\(key)@\(Int(targetSize))"

        if let cached = ImageMemoryCache.shared.image(for: cacheKey) {
            completion(cached)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            // 磁盘命中（存的是压缩小图）
            if let data = ImageDiskCache.data(for: key),
               let image = ImageDownsampler.downsample(data: data, to: targetSize, scale: scale) {
                ImageMemoryCache.shared.store(image, for: cacheKey)
                DispatchQueue.main.async { completion(image) }
                return
            }

            // 去重：同一 URL 已在下载则直接返回
            self.lock.lock()
            let alreadyLoading = self.inFlight.contains(key)
            if !alreadyLoading { self.inFlight.insert(key) }
            self.lock.unlock()

            if alreadyLoading {
                // 稍后重试一次（等首个请求把缓存写好）
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
                    if let data = ImageDiskCache.data(for: key),
                       let image = ImageDownsampler.downsample(data: data, to: targetSize, scale: scale) {
                        ImageMemoryCache.shared.store(image, for: cacheKey)
                        DispatchQueue.main.async { completion(image) }
                    } else {
                        DispatchQueue.main.async { completion(nil) }
                    }
                }
                return
            }

            self.semaphore.wait()
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

            let task = self.session.dataTask(with: request) { data, response, _ in
                defer {
                    self.semaphore.signal()
                    self.lock.lock()
                    self.inFlight.remove(key)
                    self.lock.unlock()
                }

                guard let data, !data.isEmpty,
                      let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                // 关键：写盘的只有压缩后的小图
                if let small = ImageDownsampler.compressedForStorage(data: data) {
                    ImageDiskCache.store(small, for: key)
                }

                guard let image = ImageDownsampler.downsample(data: data, to: targetSize, scale: scale) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                ImageMemoryCache.shared.store(image, for: cacheKey)
                DispatchQueue.main.async { completion(image) }
            }
            task.resume()
        }
    }

    /// 内存警告时只清内存，磁盘保留
    func flushMemory() { ImageMemoryCache.shared.removeAll() }
}

// MARK: - SwiftUI 包装

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    var targetSize: CGFloat = 120
    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear(perform: load)
        .onChange(of: url) { _ in
            image = nil
            didFail = false
            load()
        }
    }

    private func load() {
        guard image == nil, !didFail, let url else { return }
        ImageLoader.shared.load(url: url, targetSize: targetSize) { result in
            if let result { self.image = result } else { self.didFail = true }
        }
    }
}
