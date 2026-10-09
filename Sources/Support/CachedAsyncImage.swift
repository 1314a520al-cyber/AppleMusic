//
//  CachedAsyncImage.swift
//  AppleMusic
//
//  带两级缓存（内存 + 磁盘）的异步图片加载，用 ImageIO 按显示尺寸降采样解码，
//  避免大图整张展开进内存导致列表卡顿。
//

import SwiftUI
import UIKit
import ImageIO

// MARK: - 内存缓存

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 150
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    func image(for key: String) -> UIImage? { cache.object(forKey: key as NSString) }

    func store(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func removeAll() { cache.removeAllObjects() }
}

// MARK: - 磁盘缓存

enum ImageDiskCache {
    private static let folderName = "AMImageCache"

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func fileURL(for key: String) -> URL? {
        guard let directory else { return nil }
        let safe = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "=", with: "_")
        return directory.appendingPathComponent(safe)
    }

    static func data(for key: String) -> Data? {
        guard let url = fileURL(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func store(_ data: Data, for key: String) {
        guard let url = fileURL(for: key) else { return }
        try? data.write(to: url, options: .atomic)
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
            let size = (try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return total
    }
}

// MARK: - 降采样

enum ImageDownsampler {
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
}

// MARK: - 加载器

final class ImageLoader {
    static let shared = ImageLoader()

    /// 限制并发解码数，避免同刻太多图打满 CPU 掉帧
    private let semaphore = DispatchSemaphore(value: 4)
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .returnCacheDataElseLoad
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

            if let data = ImageDiskCache.data(for: key),
               let image = ImageDownsampler.downsample(data: data, to: targetSize, scale: scale) {
                ImageMemoryCache.shared.store(image, for: cacheKey)
                DispatchQueue.main.async { completion(image) }
                return
            }

            self.semaphore.wait()
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

            let task = self.session.dataTask(with: request) { data, response, _ in
                defer { self.semaphore.signal() }
                guard let data, !data.isEmpty,
                      let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                ImageDiskCache.store(data, for: key)
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
