//
//  SearchView.swift
//  AppleMusic
//
//  「搜索」：三平台切换搜索 + 历史 + 热搜。
//

import SwiftUI

enum SearchPlatform: String, CaseIterable, Identifiable {
    case netease
    case qq
    case kugou

    var id: String { rawValue }

    var title: String {
        switch self {
        case .netease: return "网易云"
        case .qq:      return "QQ 音乐"
        case .kugou:   return "酷狗"
        }
    }
}

struct SearchView: View {
    @Binding var showNowPlaying: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var favorites: FavoritesStore
    @ObservedObject private var history = SearchHistoryStore.shared

    @State private var keyword = ""
    @State private var platform: SearchPlatform = .netease
    @State private var results: [Song] = []
    @State private var hotWords: [String] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorText: String?
    @State private var selectedSong: Song?

    @FocusState private var searchFocused: Bool

    var body: some View {
        CompatNavigationStack {
            ZStack {
                AmbienceBackdrop(tint: .accentColor)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("搜索")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        searchField.padding(.horizontal, 20)
                        platformPicker.padding(.horizontal, 20)

                        if isSearching {
                            LoadingStateView(text: "搜索中…")
                        } else if hasSearched {
                            searchResultsSection
                        } else {
                            discoverySection
                        }

                        Spacer(minLength: 150)
                    }
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationBarHidden(true)
        }
        .task { await loadHotWords() }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 15)).foregroundStyle(.secondary)

            TextField("歌曲、歌手、专辑", text: $keyword)
                .font(.system(size: 16))
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { performSearch() }

            if !keyword.isEmpty {
                Button {
                    keyword = ""; results = []; hasSearched = false
                } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background { RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.07)) }
    }

    private var platformPicker: some View {
        HStack(spacing: 8) {
            ForEach(SearchPlatform.allCases) { item in
                Button {
                    guard platform != item else { return }
                    Haptics.select()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { platform = item }
                    if hasSearched { performSearch() }
                } label: {
                    Text(item.title)
                        .font(.system(size: 14, weight: platform == item ? .semibold : .regular))
                        .foregroundStyle(platform == item ? Color.white : Color.primary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background {
                            Capsule().fill(platform == item ? Color.accentColor : Color.primary.opacity(0.07))
                        }
                }
                .buttonStyle(PressableButtonStyle(scale: 0.95))
            }
            Spacer(minLength: 0)
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let errorText {
                EmptyStateView(icon: "exclamationmark.magnifyingglass", title: "搜索失败", message: errorText)
            } else if results.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "没有找到结果",
                               message: "换个关键词，或切换其他平台试试")
            } else {
                GroupCaption(text: "\(platform.title) · \(results.count) 个结果")
                ForEach(Array(results.enumerated()), id: \.element.identityKey) { index, song in
                    SongRow(
                        song: song,
                        isCurrent: player.currentSong?.identityKey == song.identityKey,
                        isPlaying: player.isPlaying,
                        onTap: {
                            player.play(songs: results, startAt: index)
                            showNowPlaying = true
                        },
                        onMore: { selectedSong = song }
                    )
                    if index < results.count - 1 { InsetDivider() }
                }
            }
        }
    }

    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !history.keywords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionTitle(text: "最近搜索")
                        Spacer()
                        Button("清除") { history.clear(); Haptics.tap() }
                            .font(.system(size: 14)).foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal, 20)

                    FlowLayout(spacing: 8, items: history.keywords) { word in
                        keyword = word
                        performSearch()
                    }
                    .padding(.horizontal, 20)
                }
            }

            if !hotWords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "热门搜索").padding(.horizontal, 20)
                    FlowLayout(spacing: 8, items: hotWords) { word in
                        keyword = word
                        performSearch()
                    }
                    .padding(.horizontal, 20)
                }
            } else if history.keywords.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "搜索你想听的音乐",
                               message: "支持网易云、QQ 音乐、酷狗三个平台")
            }
        }
    }

    private func performSearch() {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        searchFocused = false
        history.record(query)
        isSearching = true
        hasSearched = true
        errorText = nil
        results = []

        Task {
            var found: [Song] = []
            do {
                switch platform {
                case .netease: found = try await NetEaseAPI.shared.search(keyword: query, limit: 30)
                case .qq:      found = try await QQMusicAPI.shared.searchSongs(keyword: query, limit: 30)
                case .kugou:   found = try await KugouMusicAPI.shared.searchSongs(keyword: query, limit: 30)
                }
            } catch {
                await MainActor.run { errorText = error.localizedDescription }
            }
            await MainActor.run { results = found; isSearching = false }
        }
    }

    private func loadHotWords() async {
        guard hotWords.isEmpty else { return }
        var words: [String] = []
        if let list = try? await NetEaseAPI.shared.hotSearch(), !list.isEmpty {
            words = list
        } else if let list = try? await QQMusicAPI.shared.hotKeys(limit: 12), !list.isEmpty {
            words = list
        }
        await MainActor.run { hotWords = Array(words.prefix(12)) }
    }
}

// MARK: - 流式标签布局（iOS 15 兼容）

struct FlowLayout: View {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    let items: [String]
    let onTap: (String) -> Void

    @State private var sizes: [String: CGSize] = [:]

    var body: some View {
        GeometryReader { geo in
            buildRows(maxWidth: geo.size.width)
        }
        .frame(height: estimatedHeight)
        .background {
            VStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: FlowSizeKey.self, value: [item: proxy.size])
                            }
                        )
                }
            }
            .hidden()
        }
        .onPreferenceChange(FlowSizeKey.self) { sizes = $0 }
    }

    @ViewBuilder
    private func buildRows(maxWidth: CGFloat) -> some View {
        let rows = arrange(maxWidth: maxWidth)
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            Haptics.tap()
                            onTap(item)
                        } label: {
                            Text(item)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background { Capsule().fill(Color.primary.opacity(0.07)) }
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.95))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func arrange(maxWidth: CGFloat) -> [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        var currentWidth: CGFloat = 0
        let usable = max(maxWidth, 1)

        for item in items {
            let width = sizes[item]?.width ?? (CGFloat(item.count) * 14 + 28)
            if currentWidth + width > usable, !current.isEmpty {
                rows.append(current); current = []; currentWidth = 0
            }
            current.append(item)
            currentWidth += width + spacing
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    private var estimatedHeight: CGFloat {
        guard !items.isEmpty else { return 0 }
        let rows = arrange(maxWidth: 320)
        let rowHeight: CGFloat = sizes.values.map(\.height).max() ?? 36
        return CGFloat(rows.count) * rowHeight + CGFloat(max(0, rows.count - 1)) * lineSpacing
    }
}

struct FlowSizeKey: PreferenceKey {
    static var defaultValue: [String: CGSize] = [:]
    static func reduce(value: inout [String: CGSize], nextValue: () -> [String: CGSize]) {
        value.merge(nextValue()) { _, new in new }
    }
}
