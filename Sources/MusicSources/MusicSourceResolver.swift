//
//  MusicSourceResolver.swift
//  AppleMusic
//
//  并发请求所有可用音源，最快返回可播放直链的胜出。
//

import Foundation

enum MusicSourceResolver {

    struct Resolved {
        let url: URL
        let sourceTitle: String
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 7
        config.timeoutIntervalForResource = 12
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    static func resolve(song: Song, quality: AudioQuality) async -> Resolved? {
        let sources = MusicSourceStore.shared.usableSources
        guard !sources.isEmpty else { return nil }

        var seen = Set<String>()
        let unique = sources.filter { seen.insert(fingerprint($0)).inserted }

        return await withTaskGroup(of: Resolved?.self) { group in
            for source in unique {
                group.addTask { await request(source: source, song: song, quality: quality) }
            }
            for await result in group {
                if let result {
                    group.cancelAll()
                    return result
                }
            }
            return nil
        }
    }

    static func test(source: MusicSource, sample: Song) async -> String? {
        if let resolved = await request(source: source, song: sample, quality: AudioQuality.current) {
            return resolved.url.absoluteString
        }
        return nil
    }

    private static func fingerprint(_ source: MusicSource) -> String {
        let headers = source.headers
            .filter { $0.key != "quality" }
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        return source.template + "|" + headers
    }

    private static func request(source: MusicSource, song: Song, quality: AudioQuality) async -> Resolved? {
        guard source.isUsable else { return nil }

        let songID = platformID(for: song)
        let provider = providerCode(for: song.source)
        let keyword = [song.name, song.artists].filter { !$0.isEmpty }.joined(separator: " ")

        var urlString = source.template
        urlString = urlString.replacingOccurrences(of: "{id}", with: songID)
        urlString = urlString.replacingOccurrences(of: "{source}", with: provider)
        urlString = urlString.replacingOccurrences(of: "{quality}", with: quality.sourceQuality)
        urlString = urlString.replacingOccurrences(of: "{name}", with: urlEncoded(song.name))
        urlString = urlString.replacingOccurrences(of: "{keyword}", with: urlEncoded(keyword))
        urlString = urlString.replacingOccurrences(of: "{artist}", with: urlEncoded(song.artists))
        urlString = urlString.replacingOccurrences(of: "{key}", with: urlEncoded(source.cardKey))

        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        if let apiKey = source.headers["apiKey"], !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        } else if !source.cardKey.isEmpty {
            request.setValue(source.cardKey, forHTTPHeaderField: "X-API-Key")
            request.setValue(source.cardKey, forHTTPHeaderField: "Authorization")
        }

        let metadataOnly: Set<String> = ["quality", "apiKey", "source"]
        for (key, value) in source.headers where !metadataOnly.contains(key) {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
            guard let rawURL = valueAtAnyPath(object, source.urlPath) as? String, !rawURL.isEmpty else { return nil }

            let cleaned = rawURL.replacingOccurrences(of: "&amp;", with: "&")
            guard let playURL = URL(string: cleaned), playURL.scheme?.hasPrefix("http") == true else { return nil }
            guard !cleaned.lowercased().contains("404") else { return nil }

            return Resolved(url: playURL, sourceTitle: source.name)
        } catch {
            BeansLogger.shared.log("音源 \(source.name) 请求失败：\(error.localizedDescription)", level: .debug)
            return nil
        }
    }

    private static func platformID(for song: Song) -> String {
        switch song.source {
        case .netease: return String(song.id)
        case .qq:      return song.qqMid ?? String(song.id)
        case .kugou:   return song.kugouHash ?? String(song.id)
        }
    }

    private static func providerCode(for source: SongSource) -> String {
        switch source {
        case .netease: return "netease"
        case .qq:      return "tencent"
        case .kugou:   return "kugou"
        }
    }

    private static func valueAtAnyPath(_ object: Any, _ paths: String) -> Any? {
        for path in paths.components(separatedBy: "|") {
            let trimmed = path.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if let value = valueAtPath(object, trimmed) { return value }
        }
        return nil
    }

    private static func valueAtPath(_ object: Any, _ path: String) -> Any? {
        var current: Any = object
        for segment in path.components(separatedBy: ".") {
            if let dict = current as? [String: Any] {
                guard let next = dict[segment] else { return nil }
                current = next
            } else if let array = current as? [Any], let index = Int(segment) {
                guard index >= 0, index < array.count else { return nil }
                current = array[index]
            } else {
                return nil
            }
        }
        return current
    }

    private static func urlEncoded(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}
