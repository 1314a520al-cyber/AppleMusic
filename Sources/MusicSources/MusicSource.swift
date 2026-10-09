//
//  MusicSource.swift
//  AppleMusic
//
//  音源模型。占位符：{id} {source} {quality} {name} {artist} {keyword} {key}
//

import Foundation

struct MusicSource: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var template: String
    var urlPath: String = "url"
    var headers: [String: String] = [:]
    var enabled: Bool = true
    var requiresKey: Bool = false
    var cardKey: String = ""
    var createdAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, name, template, urlPath, headers, enabled, requiresKey, cardKey, createdAt
    }

    init(id: String = UUID().uuidString, name: String, template: String, urlPath: String = "url",
         headers: [String: String] = [:], enabled: Bool = true, requiresKey: Bool = false,
         cardKey: String = "", createdAt: Date = Date()) {
        self.id = id; self.name = name; self.template = template; self.urlPath = urlPath
        self.headers = headers; self.enabled = enabled; self.requiresKey = requiresKey
        self.cardKey = cardKey; self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "未命名音源"
        template = try c.decodeIfPresent(String.self, forKey: .template) ?? ""
        urlPath = try c.decodeIfPresent(String.self, forKey: .urlPath) ?? "url"
        headers = try c.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        requiresKey = try c.decodeIfPresent(Bool.self, forKey: .requiresKey) ?? false
        cardKey = try c.decodeIfPresent(String.self, forKey: .cardKey) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    var missingKey: Bool {
        requiresKey && cardKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isUsable: Bool {
        enabled && !template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !missingKey
    }

    static func inferRequiresKey(template: String, headers: [String: String]) -> Bool {
        if template.contains("{key}") { return true }
        let keyLike = ["apikey", "api_key", "key", "token", "authorization", "authtoken"]
        for name in headers.keys where keyLike.contains(name.lowercased()) { return true }
        return false
    }
}
