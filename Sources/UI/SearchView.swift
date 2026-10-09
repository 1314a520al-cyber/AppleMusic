//
//  SearchView.swift
//  AppleMusic
//
//  「搜索」。
//
//  结构（对照参考图）：
//    左上「搜索」大标题 + 右上角圆形头像
//    搜索框（灰底圆角：放大镜 + 占位文字 + 麦克风）
//    「类别浏览」双列彩色卡片（图片铺满 + 左下角白色标签）
//    搜索后：平台切换 + 结果列表
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
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var history = SearchHistoryStore.shared

    @State private var keyword = ""
    @State private var platform: SearchPlatform = .netease
    @State private var results: [Song] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorText: String?
    @State private var selectedSong: Song?

    @FocusState private var searchFocused: Bool

    private let categories: [(String, [Color])] = [
        ("国语流行", [Color(red: 0.55, green: 0.30, blue: 0.85), Color(red: 0.30, green: 0.20, blue: 0.60)]),
        ("K-Pop",    [Color(red: 0.90, green: 0.40, blue: 0.55), Color(red: 0.60, green: 0.20, blue: 0.40)]),
        ("国际流行", [Color(red: 0.20, green: 0.55, blue: 0.90), Color(red: 0.10, green: 0.30, blue: 0.65)]),
        ("粤语流行", [Color(red: 0.95, green: 0.55, blue: 0.25), Color(red: 0.70, green: 0.30, blue: 0.15)]),
        ("嘻哈说唱", [Color(red: 0.25, green: 0.70, blue: 0.60), Color(red: 0.10, green: 0.40, blue: 0.40)]),
        ("独家精选", [Color(red: 0.85, green: 0.30, blue: 0.35), Color(red: 0.55, green: 0.15, blue: 0.25)])
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        header

                        searchField
                            .padding(.horizontal, 16)

                        if isSearching {
                            LoadingStateView(text: "搜索中…")
                        } else if hasSearched {
                            resultsSection
                        } else {
                            browseSection
                        }

                        Spacer(minLength: 170)
                    }
                    .padding(.top, 6)
                }
                .compatScrollIndicatorsHidden()
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedSong) { song in
            SongSheetContainer(song: song)
                .environmentObject(player)
                .environmentObject(favorites)
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .center) {
            Text("搜索")
                .font(.system(size: 34, weight: .bold))

            Spacer()

            if settings.showTopLeftAvatar {
                AvatarButton()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            TextField("艺人、歌曲、歌词以及更多内容", text: $keyword)
                .font(.system(size: 16))
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { performSearch() }

            if keyword.isEmpty {
                Image(systemName: "mic.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    keyword = ""
                    results = []
                    hasSearched = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.08))
        }
    }

    // MARK: - 类别浏览

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("类别浏览")
                .font(.system(size: 22, weight: .bold))
                .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories, id: \.0) { name, colors in
                    Button {
                        keyword = name
                        performSearch()
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(colors: colors,
                                           startPoint: .topLeading, endPoint: .bottomTrailing)

                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.14))
                                .offset(x: 62, y: -8)

                            Text(name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(12)
                        }
                        .frame(height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.97))
                }
            }
            .padding(.horizontal, 16)

            // 最近搜索
            if !history.keywords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("最近搜索")
                            .font(.system(size: 22, weight: .bold))
                        Spacer()
                        Button("清除") { history.clear(); Haptics.tap() }
                            .font(.system(size: 15))
                            .foregroundStyle(settings.accent.color)
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 0) {
                        ForEach(history.keywords, id: \.self) { word in
                            Button {
                                keyword = word
                                performSearch()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 22)
                                    Text(word)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.primary)
                                    Spacer(minLength: 0)
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 11)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, opacity: 0.9))
                        }
                    }
                }
            }
        }
    }

    // MARK: - 搜索结果

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            platformPicker
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            if let errorText {
                EmptyStateView(icon: "exclamationmark.magnifyingglass", title: "搜索失败", message: errorText)
            } else if results.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "没有找到结果",
                               message: "换个关键词，或切换其他平台试试")
            } else {
                ForEach(Array(results.enumerated()), id: \.element.identityKey) { index, song in
                    SongRow(
                        song: song,
                        isCurrent: player.currentSong?.identityKey == song.identityKey,
                        isPlaying: player.isPlaying,
                        onTap: {
                            player.play(songs: results, startAt: index)
                            showNowPlaying = true
                        },
                        onMore: settings.showSongRowMore ? { selectedSong = song } : nil
                    )
                    if index < results.count - 1 { InsetDivider() }
                }
            }
        }
    }

    private var platformPicker: some View {
        HStack(spacing: 8) {
            ForEach(SearchPlatform.allCases) { item in
                Button {
                    guard platform != item else { return }
                    Haptics.select()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { platform = item }
                    performSearch()
                } label: {
                    Text(item.title)
                        .font(.system(size: 14, weight: platform == item ? .semibold : .regular))
                        .foregroundStyle(platform == item ? Color.white : Color.primary)
                        .padding(.horizontal, 16).padding(.vertical, 7)
                        .background {
                            Capsule().fill(platform == item ? settings.accent.color : Color.primary.opacity(0.08))
                        }
                }
                .buttonStyle(PressableButtonStyle(scale: 0.95))
            }
            Spacer(minLength: 0)
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
}
