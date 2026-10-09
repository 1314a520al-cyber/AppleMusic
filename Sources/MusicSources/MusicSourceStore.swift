//
//  MusicSourceStore.swift
//  AppleMusic
//
//  音源增删改查 + 持久化。
//

import Foundation
import Combine

final class MusicSourceStore: ObservableObject {
    static let shared = MusicSourceStore()

    @Published private(set) var sources: [MusicSource] = []
    private let key = "appleMusic.sources.v1"

    private init() {
        load()
        if sources.isEmpty { seedBuiltIn() }
    }

    private func seedBuiltIn() {
        sources = [
            MusicSource(
                id: "builtin.gdstudio",
                name: "公开音源 · 聚合",
                template: "https://music-api.gdstudio.xyz/api.php?types=url&source=netease&id={id}&br=320",
                urlPath: "url",
                headers: [:],
                enabled: true,
                requiresKey: false
            )
        ]
        save()
    }

    var usableSources: [MusicSource] { sources.filter { $0.isUsable } }

    func source(id: String) -> MusicSource? { sources.first { $0.id == id } }

    func add(_ source: MusicSource) {
        var newSource = source
        if newSource.createdAt.timeIntervalSince1970 < 1 { newSource.createdAt = Date() }
        sources.append(newSource)
        save()
    }

    @discardableResult
    func add(parsed: ParsedMusicSource, cardKey: String = "") -> MusicSource {
        let source = MusicSource(
            name: parsed.name, template: parsed.template, urlPath: parsed.urlPath,
            headers: parsed.headers, enabled: true, requiresKey: parsed.requiresKey, cardKey: cardKey
        )
        sources.append(source)
        save()
        return source
    }

    func update(_ source: MusicSource) {
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        sources[index] = source
        save()
    }

    func remove(id: String) { sources.removeAll { $0.id == id }; save() }

    func setEnabled(id: String, enabled: Bool) {
        guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[index].enabled = enabled
        save()
    }

    func setCardKey(id: String, key: String) {
        guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[index].cardKey = key
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MusicSource].self, from: data) else { return }
        sources = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(sources) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
