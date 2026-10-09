//
//  PlayerManager.swift
//  AppleMusic
//
//  播放核心：AVPlayer + 队列 + 三平台解析 + 音源兜底。
//

import AVFoundation
import MediaPlayer
import Foundation
import UIKit
import Combine

enum PlayMode: String, CaseIterable, Identifiable {
    case sequential
    case repeatAll
    case repeatOne
    case shuffle

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sequential: return "arrow.right"
        case .repeatAll:  return "repeat"
        case .repeatOne:  return "repeat.1"
        case .shuffle:    return "shuffle"
        }
    }

    var title: String {
        switch self {
        case .sequential: return "顺序播放"
        case .repeatAll:  return "列表循环"
        case .repeatOne:  return "单曲循环"
        case .shuffle:    return "随机播放"
        }
    }

    var next: PlayMode {
        switch self {
        case .sequential: return .repeatAll
        case .repeatAll:  return .repeatOne
        case .repeatOne:  return .shuffle
        case .shuffle:    return .sequential
        }
    }
}

@MainActor
final class PlayerManager: NSObject, ObservableObject {

    static var shared: PlayerManager?

    @Published var queue: [Song] = []
    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var loadFailed = false
    @Published var playMode: PlayMode = .sequential
    @Published var notice: String?
    @Published var lyrics: [LyricLine] = []
    @Published var isLoadingLyrics = false

    let clock = PlaybackClock()

    var currentSong: Song? {
        guard currentIndex >= 0, currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var tickTimer: Timer?

    private var loadGeneration = 0
    private var lastLoadedKey: String?
    private var pendingSeekTarget: Double?
    private var lastAutoAdvance = Date(timeIntervalSince1970: 0)


    private override init() {
        super.init()
        configureAudioSession()
        registerRemoteCommands()
        startTicking()
    }

    static func makeShared() -> PlayerManager {
        let manager = PlayerManager()
        PlayerManager.shared = manager
        return manager
    }

    // MARK: - 播放控制

    func play(songs: [Song], startAt index: Int = 0) {
        guard !songs.isEmpty else { return }
        queue = songs
        currentIndex = max(0, min(index, songs.count - 1))
        loadCurrent(forceReload: true)
    }

    func playSong(_ song: Song, in context: [Song]) {
        if let index = context.firstIndex(where: { $0.identityKey == song.identityKey }) {
            play(songs: context, startAt: index)
        } else {
            play(songs: [song])
        }
    }

    func playNext(_ song: Song) {
        if queue.isEmpty { play(songs: [song]); return }
        let insertAt = min(currentIndex + 1, queue.count)
        queue.insert(song, at: insertAt)
        Haptics.success()
        ToastCenter.shared.show("已加入下一首播放", icon: "text.insert")
    }

    func playLocalFile(url: URL, song: Song) {
        notice = "本地播放"
        let item = AVPlayerItem(url: url)
        if let existing = player { existing.replaceCurrentItem(with: item) }
        else { player = AVPlayer(playerItem: item) }
        observeStatus(of: item)
        observeEnd(of: item)
        player?.play()
        isPlaying = true
        isBuffering = false
        updateNowPlaying(song: song)
    }

    func togglePlayPause() {
        guard player != nil else {
            if currentSong != nil { loadCurrent(forceReload: false) }
            return
        }
        if isPlaying { player?.pause(); isPlaying = false }
        else { player?.play(); isPlaying = true }
        updateNowPlayingPlaybackState()
        Haptics.tap()
    }

    func next(manual: Bool = true) {
        guard !queue.isEmpty else { return }

        if playMode == .repeatOne && !manual {
            seek(to: 0); player?.play(); isPlaying = true; return
        }

        if playMode == .shuffle {
            currentIndex = Int.random(in: 0..<queue.count)
            loadCurrent(forceReload: true)
            return
        }

        let isLast = currentIndex >= queue.count - 1
        if isLast {
            if playMode == .repeatAll || manual {
                currentIndex = 0
                loadCurrent(forceReload: true)
            } else {
                player?.pause(); isPlaying = false; seek(to: 0)
            }
        } else {
            currentIndex += 1
            loadCurrent(forceReload: true)
        }
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if clock.progress > 3 { seek(to: 0); return }
        if currentIndex > 0 { currentIndex -= 1 }
        else { currentIndex = max(0, queue.count - 1) }
        loadCurrent(forceReload: true)
    }

    func seek(to seconds: Double) {
        let target = max(0, seconds)
        pendingSeekTarget = target
        clock.forceUpdate(progress: target)
        guard let player else { return }
        let cmTime = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self else { return }
            self.pendingSeekTarget = nil
        }
        updateNowPlayingPlaybackState()
    }

    func seekBy(_ delta: Double) {
        let current = clock.progress
        let target = max(0, min(clock.duration > 0 ? clock.duration : current + delta, current + delta))
        seek(to: target)
    }

    func togglePlayMode() {
        playMode = playMode.next
        Haptics.select()
    }

    func setPlayMode(_ mode: PlayMode) { playMode = mode; Haptics.select() }

    func removeFromQueue(at offsets: IndexSet) {
        let currentKey = currentSong?.identityKey
        for index in offsets.sorted(by: >) where index < queue.count { queue.remove(at: index) }
        if let key = currentKey, let newIndex = queue.firstIndex(where: { $0.identityKey == key }) {
            currentIndex = newIndex
        } else {
            currentIndex = min(currentIndex, max(0, queue.count - 1))
        }
    }

    func clearQueue() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        queue = []; currentIndex = 0; isPlaying = false; lyrics = []
        clock.forceUpdate(progress: 0)
        clock.update(duration: 0)
    }

    func retryCurrent() {
        loadFailed = false
        loadCurrent(forceReload: true)
    }

    // MARK: - 加载

    private func loadCurrent(forceReload: Bool) {
        guard let song = currentSong else { return }

        loadGeneration += 1
        let generation = loadGeneration

        let isSameSong = lastLoadedKey == song.identityKey
        if !isSameSong || forceReload {
            clock.forceUpdate(progress: 0)
            clock.update(duration: song.duration > 0 ? song.duration : 0)
            pendingSeekTarget = nil
        }
        lastLoadedKey = song.identityKey
        loadFailed = false
        isBuffering = true
        PlayHistoryStore.shared.record(song)

        let quality = AudioQuality.current

        Task { [weak self] in
            guard let self else { return }

            if let cached = PlaybackURLCache.url(for: song.identityKey) {
                await MainActor.run {
                    guard generation == self.loadGeneration else { return }
                    self.startPlayback(url: cached, song: song)
                }
                return
            }

            var resolved: URL?
            var sourceNote: String?

            switch song.source {
            case .netease: resolved = await self.resolveNetease(song: song, quality: quality)
            case .qq:      resolved = await self.resolveQQ(song: song, quality: quality)
            case .kugou:   resolved = await self.resolveKugou(song: song)
            }

            if resolved == nil {
                if let fallback = await MusicSourceResolver.resolve(song: song, quality: quality) {
                    resolved = fallback.url
                    sourceNote = fallback.sourceTitle
                }
            }

            if Task.isCancelled { return }

            await MainActor.run {
                guard generation == self.loadGeneration else { return }
                guard let resolved else {
                    self.isBuffering = false
                    self.loadFailed = true
                    BeansLogger.shared.log("✗ 播放失败（无可用地址）：\(song.name)", level: .error)
                    return
                }
                PlaybackURLCache.store(resolved, for: song.identityKey)
                self.startPlayback(url: resolved, song: song, sourceNote: sourceNote)
            }
        }

        loadLyrics(for: song)
    }

    private func resolveNetease(song: Song, quality: AudioQuality) async -> URL? {
        do {
            let map = try await NetEaseAPI.shared.songURLs(ids: [song.id], level: quality.neteaseLevel)
            if let raw = map[song.id], let url = URL(string: raw) { return url }
        } catch {
            BeansLogger.shared.log("网易云取地址失败：\(error.localizedDescription)", level: .warn)
        }
        return nil
    }

    private func resolveQQ(song: Song, quality: AudioQuality) async -> URL? {
        guard let mid = song.qqMid else { return nil }
        do {
            if let raw = try await QQMusicAPI.shared.songURL(songmid: mid, mediaMid: song.qqMediaMid),
               let url = URL(string: raw) { return url }
        } catch {
            BeansLogger.shared.log("QQ 取地址失败：\(error.localizedDescription)", level: .warn)
        }
        return nil
    }

    private func resolveKugou(song: Song) async -> URL? {
        do {
            if let raw = try await KugouMusicAPI.shared.songURL(song: song), let url = URL(string: raw) { return url }
        } catch {
            BeansLogger.shared.log("酷狗取地址失败：\(error.localizedDescription)", level: .warn)
        }
        return nil
    }

    private func startPlayback(url: URL, song: Song, sourceNote: String? = nil) {
        notice = sourceNote.map { "来自 \($0)" }

        let item = AVPlayerItem(url: url)
        // 只预缓冲 2 秒：默认值会吞掉大量内存与网络缓存，
        // 对在线流媒体没必要，也是内存占用偏高的原因之一。
        item.preferredForwardBufferDuration = 2

        if let existing = player { existing.replaceCurrentItem(with: item) }
        else {
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            player = newPlayer
        }

        observeStatus(of: item)
        observeEnd(of: item)

        player?.play()
        isPlaying = true
        isBuffering = false
        updateNowPlaying(song: song)
        BeansLogger.shared.log("▶ 播放：\(song.name) - \(song.artists)", level: .info)
    }

    private func observeStatus(of item: AVPlayerItem) {
        statusObserver?.invalidate()
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    self.isBuffering = false
                    let duration = item.duration.seconds
                    if duration.isFinite, duration > 0 { self.clock.update(duration: duration) }
                case .failed:
                    self.isBuffering = false
                    self.loadFailed = true
                    BeansLogger.shared.log("✗ 播放失败：\(item.error?.localizedDescription ?? "未知")", level: .error)
                default:
                    break
                }
            }
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let now = Date()
            guard now.timeIntervalSince(self.lastAutoAdvance) > 0.5 else { return }
            self.lastAutoAdvance = now
            Task { @MainActor in self.next(manual: false) }
        }
    }

    // MARK: - 进度

    private func startTicking() {
        tickTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func tick() {
        guard let player, let item = player.currentItem else { return }
        let current = item.currentTime().seconds
        guard current.isFinite else { return }

        if let target = pendingSeekTarget {
            if abs(current - target) > 1.0 { return }
            pendingSeekTarget = nil
        }

        clock.update(progress: current)
        let duration = item.duration.seconds
        if duration.isFinite, duration > 0 { clock.update(duration: duration) }
    }

    deinit {
        tickTimer?.invalidate()
        statusObserver?.invalidate()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    // MARK: - 歌词

    func loadLyrics(for song: Song) {
        lyrics = []
        isLoadingLyrics = true

        Task { [weak self] in
            guard let self else { return }
            var raw: String?
            var translation: String?

            switch song.source {
            case .netease:
                if let result = try? await NetEaseAPI.shared.lyricWithTranslation(id: song.id) {
                    raw = result.lrc
                    translation = result.tlyric
                }
            case .qq:
                if let mid = song.qqMid { raw = try? await QQMusicAPI.shared.lyric(songmid: mid) }
            case .kugou:
                if let hash = song.kugouHash, !hash.isEmpty {
                    let text = await KugouMusicAPI.shared.lyric(hash: hash, duration: song.duration)
                    raw = text.isEmpty ? nil : text
                }
            }

            let parsed = raw.map { LyricParser.parse($0, translationRaw: translation) } ?? []
            await MainActor.run {
                guard self.currentSong?.identityKey == song.identityKey else { return }
                self.lyrics = parsed
                self.isLoadingLyrics = false
            }
        }
    }

    // MARK: - 音频会话

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            BeansLogger.shared.log("音频会话配置失败：\(error.localizedDescription)", level: .warn)
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruptionRaw(_:)),
            name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRouteChangeRaw(_:)),
            name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance()
        )
    }

    @objc nonisolated private func handleInterruptionRaw(_ note: Notification) {
        let info = note.userInfo
        Task { @MainActor in self.handleInterruption(info) }
    }

    @objc nonisolated private func handleRouteChangeRaw(_ note: Notification) {
        let info = note.userInfo
        Task { @MainActor in self.handleRouteChange(info) }
    }

    private func handleInterruption(_ info: [AnyHashable: Any]?) {
        guard let info,
              let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }

        switch type {
        case .began:
            isPlaying = false
        case .ended:
            let optionsRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if AVAudioSession.InterruptionOptions(rawValue: optionsRaw).contains(.shouldResume) {
                player?.play()
                isPlaying = true
            }
        @unknown default:
            break
        }
        updateNowPlayingPlaybackState()
    }

    private func handleRouteChange(_ info: [AnyHashable: Any]?) {
        guard let info,
              let rawReason = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else { return }
        if reason == .oldDeviceUnavailable {
            player?.pause()
            isPlaying = false
            updateNowPlayingPlaybackState()
        }
    }

    // MARK: - 锁屏 / 控制中心

    private func registerRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in if !self.isPlaying { self.togglePlayPause() } }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in if self.isPlaying { self.togglePlayPause() } }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.previous() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self.seek(to: e.positionTime) }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.togglePlayPause() }
            return .success
        }
    }

    private func updateNowPlaying(song: Song) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.name,
            MPMediaItemPropertyArtist: song.artists,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]
        if song.duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = song.duration }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = .playing

        if let coverURL = song.coverURL {
            ImageLoader.shared.load(url: coverURL, targetSize: 600) { image in
                guard let image else { return }
                var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? info
                updated[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
            }
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func updateNowPlayingPlaybackState() {
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = clock.progress
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - 播放地址缓存
//
// 单独抽成 enum（不参与 @MainActor 隔离），这样缓存清理可以从任意上下文调用，
// 不会触发 actor 隔离告警。内部用 NSLock 保证线程安全。
enum PlaybackURLCache {
    private static let lock = NSLock()
    private static var storage: [String: URL] = [:]

    static func url(for key: String) -> URL? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    static func store(_ url: URL, for key: String) {
        lock.lock()
        storage[key] = url
        lock.unlock()
    }

    static func clear() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }
}
