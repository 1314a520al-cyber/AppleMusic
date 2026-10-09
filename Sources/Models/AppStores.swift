//
//  AppStores.swift
//  AppleMusic
//
//  本地持久化：收藏、歌单、搜索历史、播放历史、下载。
//

import Foundation
import SwiftUI

// MARK: - 收藏

final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()
    @Published private(set) var songs: [Song] = []
    private let key = "appleMusic.favorites.v1"

    private init() { load() }

    func contains(_ song: Song) -> Bool { songs.contains { $0.identityKey == song.identityKey } }

    @discardableResult
    func toggle(_ song: Song) -> Bool {
        if let index = songs.firstIndex(where: { $0.identityKey == song.identityKey }) {
            songs.remove(at: index); save(); return false
        } else {
            songs.insert(song, at: 0); save(); return true
        }
    }

    func remove(_ song: Song) { songs.removeAll { $0.identityKey == song.identityKey }; save() }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where index < songs.count { songs.remove(at: index) }
        save()
    }

    func clear() { songs = []; save() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Song].self, from: data) else { return }
        songs = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - 歌单

struct UserPlaylist: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var songs: [Song] = []
    var createdAt: Date = Date()
    var coverURL: URL? { songs.first?.coverURL }
}

final class PlaylistStore: ObservableObject {
    static let shared = PlaylistStore()
    @Published private(set) var playlists: [UserPlaylist] = []
    private let key = "appleMusic.playlists.v1"

    private init() { load() }

    @discardableResult
    func create(name: String) -> UserPlaylist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = UserPlaylist(name: trimmed.isEmpty ? "新建歌单" : trimmed)
        playlists.append(playlist); save(); return playlist
    }

    func delete(id: String) { playlists.removeAll { $0.id == id }; save() }

    func rename(id: String, to name: String) {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playlists[index].name = trimmed; save()
    }

    @discardableResult
    func add(_ song: Song, to id: String) -> Bool {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return false }
        if playlists[index].songs.contains(where: { $0.identityKey == song.identityKey }) { return false }
        playlists[index].songs.append(song); save(); return true
    }

    func remove(song: Song, from id: String) {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[index].songs.removeAll { $0.identityKey == song.identityKey }; save()
    }

    func playlist(id: String) -> UserPlaylist? { playlists.first { $0.id == id } }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UserPlaylist].self, from: data) else { return }
        playlists = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - 搜索历史

final class SearchHistoryStore: ObservableObject {
    static let shared = SearchHistoryStore()
    @Published private(set) var keywords: [String] = []
    private let key = "appleMusic.searchHistory.v1"
    private let maxCount = 20

    private init() { keywords = UserDefaults.standard.stringArray(forKey: key) ?? [] }

    func record(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        keywords.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        keywords.insert(trimmed, at: 0)
        if keywords.count > maxCount { keywords = Array(keywords.prefix(maxCount)) }
        UserDefaults.standard.set(keywords, forKey: key)
    }

    func remove(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
        UserDefaults.standard.set(keywords, forKey: key)
    }

    func clear() { keywords = []; UserDefaults.standard.removeObject(forKey: key) }
}

// MARK: - 播放历史

final class PlayHistoryStore: ObservableObject {
    static let shared = PlayHistoryStore()
    @Published private(set) var songs: [Song] = []
    private let key = "appleMusic.playHistory.v1"
    private let maxCount = 100

    private init() { load() }

    func record(_ song: Song) {
        songs.removeAll { $0.identityKey == song.identityKey }
        songs.insert(song, at: 0)
        if songs.count > maxCount { songs = Array(songs.prefix(maxCount)) }
        save()
    }

    func clear() { songs = []; save() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Song].self, from: data) else { return }
        songs = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - 下载

final class DownloadStore: ObservableObject {
    static let shared = DownloadStore()

    struct Item: Identifiable, Codable, Hashable {
        var id: String { song.identityKey }
        let song: Song
        let fileName: String
        var sizeBytes: Int64
        var downloadedAt: Date
    }

    @Published private(set) var items: [Item] = []

    static var downloadsDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private let key = "appleMusic.downloads.v1"
    private init() { load() }

    func contains(_ song: Song) -> Bool { items.contains { $0.song.identityKey == song.identityKey } }

    func fileURL(for song: Song) -> URL? {
        guard let item = items.first(where: { $0.song.identityKey == song.identityKey }) else { return nil }
        let url = Self.downloadsDirectory.appendingPathComponent(item.fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func add(song: Song, fileName: String, sizeBytes: Int64) {
        items.removeAll { $0.song.identityKey == song.identityKey }
        items.insert(Item(song: song, fileName: fileName, sizeBytes: sizeBytes, downloadedAt: Date()), at: 0)
        save()
    }

    func delete(_ song: Song) {
        if let item = items.first(where: { $0.song.identityKey == song.identityKey }) {
            let url = Self.downloadsDirectory.appendingPathComponent(item.fileName)
            try? FileManager.default.removeItem(at: url)
        }
        items.removeAll { $0.song.identityKey == song.identityKey }
        save()
    }

    func totalSize() -> Int64 { items.reduce(0) { $0 + $1.sizeBytes } }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Item].self, from: data) else { return }
        items = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
