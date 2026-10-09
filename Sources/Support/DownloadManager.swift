//
//  DownloadManager.swift
//  AppleMusic
//
//  下载：把歌曲解析出的直链存到 Documents/Downloads。
//

import Foundation

enum DownloadError: LocalizedError {
    case noURL
    case network(String)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .noURL: return "找不到可下载的地址"
        case .network(let message): return "网络错误：\(message)"
        case .writeFailed: return "写入文件失败"
        }
    }
}

enum DownloadManager {

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    static func download(song: Song) async -> Result<URL, DownloadError> {
        guard let remote = await resolveURL(song: song) else { return .failure(.noURL) }

        do {
            let (tempURL, response) = try await session.download(from: remote)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return .failure(.network("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)"))
            }

            let ext = fileExtension(for: remote, fallback: "mp3")
            let fileName = safeFileName(song: song) + "." + ext
            let destination = DownloadStore.downloadsDirectory.appendingPathComponent(fileName)

            let fm = FileManager.default
            try? fm.removeItem(at: destination)
            do { try fm.moveItem(at: tempURL, to: destination) }
            catch { try fm.copyItem(at: tempURL, to: destination) }

            let size = (try? fm.attributesOfItem(atPath: destination.path)[.size] as? NSNumber)?.int64Value ?? 0
            await MainActor.run { DownloadStore.shared.add(song: song, fileName: fileName, sizeBytes: size) }
            BeansLogger.shared.log("✓ 下载完成：\(song.name)", level: .info)
            return .success(destination)
        } catch {
            return .failure(.network(error.localizedDescription))
        }
    }

    static func resolveURL(song: Song) async -> URL? {
        let quality = AudioQuality.current

        switch song.source {
        case .netease:
            if let map = try? await NetEaseAPI.shared.songURLs(ids: [song.id], level: quality.neteaseLevel),
               let raw = map[song.id], let url = URL(string: raw) { return url }
        case .qq:
            if let mid = song.qqMid,
               let raw = try? await QQMusicAPI.shared.songURL(songmid: mid, mediaMid: song.qqMediaMid),
               let url = URL(string: raw) { return url }
        case .kugou:
            if let raw = try? await KugouMusicAPI.shared.songURL(song: song), let url = URL(string: raw) { return url }
        }

        if let resolved = await MusicSourceResolver.resolve(song: song, quality: quality) { return resolved.url }
        return nil
    }

    private static func fileExtension(for url: URL, fallback: String) -> String {
        let ext = url.pathExtension.lowercased()
        let allowed: Set<String> = ["mp3", "m4a", "flac", "aac", "wav", "ogg", "ape"]
        return allowed.contains(ext) ? ext : fallback
    }

    private static func safeFileName(song: Song) -> String {
        let raw = "\(song.artists) - \(song.name)"
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "_")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名-\(song.id)" : String(trimmed.prefix(80))
    }
}
