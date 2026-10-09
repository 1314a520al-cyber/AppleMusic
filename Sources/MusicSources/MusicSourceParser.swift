//
//  MusicSourceParser.swift
//  AppleMusic
//
//  音源导入解析：支持纯 URL、JSON、带代码的文本。
//

import Foundation

struct ParsedMusicSource {
    var name: String
    var template: String
    var urlPath: String
    var headers: [String: String]
    var requiresKey: Bool
}

enum MusicSourceParser {

    static func parse(_ raw: String) -> ParsedMusicSource? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let json = parseJSON(text) { return json }
        guard let url = firstURL(in: text) else { return nil }
        let name = hostName(from: url) ?? "自定义音源"
        let headers = extractHeaders(inText: text)
        return ParsedMusicSource(
            name: name, template: url, urlPath: "url", headers: headers,
            requiresKey: MusicSource.inferRequiresKey(template: url, headers: headers)
        )
    }

    private static func parseJSON(_ text: String) -> ParsedMusicSource? {
        guard let json = extractFirstJSONObject(text) else { return nil }

        let templateKeys = ["template", "url", "api", "endpoint", "request", "src", "link"]
        var template: String?
        for key in templateKeys {
            if let value = json[key] as? String, value.lowercased().hasPrefix("http") { template = value; break }
        }
        if template == nil, let nested = json["data"] as? [String: Any] {
            for key in templateKeys {
                if let value = nested[key] as? String, value.lowercased().hasPrefix("http") { template = value; break }
            }
        }
        if template == nil { template = firstURL(in: text) }
        guard let template, !template.isEmpty else { return nil }

        let name = (json["name"] as? String) ?? (json["title"] as? String) ?? hostName(from: template) ?? "自定义音源"
        let urlPath = (json["urlPath"] as? String) ?? (json["path"] as? String) ?? (json["url_path"] as? String) ?? "url"

        var headers: [String: String] = [:]
        if let rawHeaders = json["headers"] as? [String: Any] {
            for (key, value) in rawHeaders {
                if let s = value as? String { headers[key] = s }
                else if let n = value as? NSNumber { headers[key] = n.stringValue }
            }
        }

        let requiresKey: Bool
        if let explicit = json["requiresKey"] as? Bool { requiresKey = explicit }
        else if let explicit = json["needKey"] as? Bool { requiresKey = explicit }
        else { requiresKey = MusicSource.inferRequiresKey(template: template, headers: headers) }

        return ParsedMusicSource(name: name, template: template, urlPath: urlPath,
                                 headers: headers, requiresKey: requiresKey)
    }

    private static func extractFirstJSONObject(_ text: String) -> [String: Any]? {
        var candidates: [String] = [text]
        if text.contains("```") {
            for part in text.components(separatedBy: "```") {
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                let stripped = trimmed.hasPrefix("json") ? String(trimmed.dropFirst(4)) : trimmed
                candidates.append(stripped.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end {
            candidates.append(String(text[start...end]))
        }
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8) else { continue }
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { return object }
            if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let first = array.first {
                return first
            }
        }
        return nil
    }

    static func firstURL(in text: String) -> String? {
        let pattern = #"https?://[^\s"'`,;)\]}>]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text) else { return nil }
        var url = String(text[matchRange])
        while let last = url.last, ".,;:)".contains(last) { url.removeLast() }
        return url
    }

    static func hostName(from urlString: String) -> String? {
        guard let host = URL(string: urlString)?.host, !host.isEmpty else { return nil }
        return host
    }

    private static func extractHeaders(inText text: String) -> [String: String] {
        var headers: [String: String] = [:]
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let colonIndex = trimmed.firstIndex(of: ":") else { continue }
            let name = String(trimmed[trimmed.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            let lower = name.lowercased()
            let headerLike = lower.contains("key") || lower.contains("token")
                || lower.contains("authorization") || lower.hasPrefix("x-")
            if headerLike, !value.isEmpty, !value.lowercased().hasPrefix("http") {
                headers[name] = value
            }
        }
        return headers
    }
}
