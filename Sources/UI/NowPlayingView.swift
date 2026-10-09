//
//  NowPlayingView.swift
//  AppleMusic
//
//  全屏播放页。
//
//  结构（与参考图一致）：
//    顶部迷你条（封面 + 歌名/歌手 + 星标 + 更多）
//    待播清单（来自 xxx）+ 右侧 随机/循环/无限
//    歌曲列表（序号/封面/歌名歌手/三横线）
//    进度条 + 时间
//    上一首 / 播放暂停 / 下一首
//    音量条
//    底部：歌词 / 电台 / 队列
//
//  各区块显示与否由设置控制。
//

import SwiftUI
import MediaPlayer

struct NowPlayingView: View {
    @Binding var isPresented: Bool

    @EnvironmentObject private var player: PlayerManager
    @EnvironmentObject private var clock: PlaybackClock
    @EnvironmentObject private var favorites: FavoritesStore
    @ObservedObject private var settings = AppSettings.shared

    @State private var dragOffset: CGFloat = 0
    @State private var showLyrics = false
    @State private var showQueue = false
    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0

    private var song: Song? { player.currentSong }

    var body: some View {
        ZStack {
            BackdropLayer()

            VStack(spacing: 0) {

                // 顶部迷你条
                topMiniBar

                // 待播清单头部 + 模式按钮
                queueHeader

                // 歌曲列表
                queueList

                Spacer(minLength: 8)

                // 进度条
                progressBar
                    .padding(.horizontal, 22)
                    .padding(.bottom, 10)

                // 播放控制
                playbackControls
                    .padding(.horizontal, 28)

                // 音量条
                if settings.showNowPlayingVolume {
                    SystemVolumeSlider()
                        .frame(height: 34)
                        .padding(.horizontal, 22)
                        .padding(.top, 6)
                }

                // 底部工具条
                if settings.showNowPlayingBottomBar {
                    bottomBar
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                }

                Spacer(minLength: 10)
            }
            .offset(y: dragOffset)
            .gesture(dismissGesture)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $showLyrics) {
            LyricsSheet().environmentObject(player).environmentObject(clock)
        }
        .sheet(isPresented: $showQueue) {
            QueueSheet().environmentObject(player)
        }
    }

    // MARK: - 顶部迷你条

    private var topMiniBar: some View {
        HStack(spacing: 10) {
            Button { Haptics.tap(); dismissView() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            CoverArtView(url: song?.coverURL, size: 40, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(song?.name ?? "未在播放")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(song?.artists ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if let song, settings.showMiniPlayerStar {
                Button {
                    Haptics.tap()
                    let liked = favorites.toggle(song)
                    ToastCenter.shared.show(liked ? "已收藏" : "已取消收藏",
                                            icon: liked ? "star.fill" : "star")
                } label: {
                    Image(systemName: favorites.contains(song) ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundStyle(favorites.contains(song) ? settings.accent.color : Color.secondary)
                        .frame(width: 34, height: 36).contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.9))
            }

            if settings.showMiniPlayerMore {
                SongMoreButton(song: song)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    // MARK: - 待播清单头

    private var queueHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("待播清单")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Text(player.notice ?? "来自 当前播放")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if settings.showNowPlayingModeButtons {
                HStack(spacing: 14) {
                    Button {
                        player.setPlayMode(.shuffle)
                        ToastCenter.shared.show("随机播放", icon: "shuffle")
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 16))
                            .foregroundStyle(player.playMode == .shuffle ? settings.accent.color : Color.secondary)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))

                    Button {
                        player.setPlayMode(.repeatAll)
                        ToastCenter.shared.show("列表循环", icon: "repeat")
                    } label: {
                        Image(systemName: "repeat")
                            .font(.system(size: 16))
                            .foregroundStyle(player.playMode == .repeatAll ? settings.accent.color : Color.secondary)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))

                    Button {
                        player.setPlayMode(.repeatOne)
                        ToastCenter.shared.show("单曲循环", icon: "repeat.1")
                    } label: {
                        Image(systemName: "repeat.1")
                            .font(.system(size: 16))
                            .foregroundStyle(player.playMode == .repeatOne ? settings.accent.color : Color.secondary)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    // MARK: - 队列列表

    private var queueList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(player.queue.enumerated()), id: \.element.identityKey) { index, item in
                    SongRow(
                        song: item,
                        index: index + 1,
                        showArtist: true,
                        isCurrent: player.currentSong?.identityKey == item.identityKey,
                        isPlaying: player.isPlaying,
                        showHandle: true,
                        onTap: {
                            player.play(songs: player.queue, startAt: index)
                        },
                        onMore: nil
                    )
                    if index < player.queue.count - 1 { InsetDivider(leading: 74) }
                }
            }
            .padding(.bottom, 8)
        }
        .compatScrollIndicatorsHidden()
    }

    // MARK: - 进度条

    private var progressBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let width = geo.size.width
                let duration = clock.duration > 0 ? clock.duration : 1
                let current = isScrubbing ? scrubValue : clock.progress
                let ratio = max(0, min(1, current / duration))

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.16)).frame(height: isScrubbing ? 7 : 4)
                    Capsule().fill(settings.accent.color)
                        .frame(width: width * CGFloat(ratio), height: isScrubbing ? 7 : 4)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let r = max(0, min(1, value.location.x / width))
                            scrubValue = Double(r) * duration
                        }
                        .onEnded { value in
                            let r = max(0, min(1, value.location.x / width))
                            player.seek(to: Double(r) * duration)
                            isScrubbing = false
                        }
                )
                .animation(.easeOut(duration: 0.15), value: isScrubbing)
            }
            .frame(height: 20)

            HStack {
                Text(timeString(isScrubbing ? scrubValue : clock.progress))
                Spacer()
                Text("-" + timeString(max(0, clock.duration - (isScrubbing ? scrubValue : clock.progress))))
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - 播放控制

    private var playbackControls: some View {
        HStack(spacing: 0) {
            Button { Haptics.tap(); player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28)).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity).frame(height: 56).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))

            Button { player.togglePlayPause() } label: {
                ZStack {
                    if player.isBuffering { ProgressView().scaleEffect(1.1) }
                    else { PlayPauseIcon(isPlaying: player.isPlaying, size: 36).foregroundStyle(.primary) }
                }
                .frame(maxWidth: .infinity).frame(height: 56).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))

            Button { Haptics.tap(); player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28)).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity).frame(height: 56).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))
        }
    }

    // MARK: - 底部工具条

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button { Haptics.tap(); showLyrics = true } label: {
                VStack(spacing: 3) {
                    Image(systemName: "quote.bubble").font(.system(size: 18))
                    Text("歌词").font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).frame(height: 46).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            Button { Haptics.tap(); showQueue = true } label: {
                VStack(spacing: 3) {
                    Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 18))
                    Text("电台").font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).frame(height: 46).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            Button { Haptics.tap(); showQueue = true } label: {
                VStack(spacing: 3) {
                    Image(systemName: "list.bullet").font(.system(size: 18))
                    Text("队列").font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).frame(height: 46).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))
        }
    }

    // MARK: - 手势

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 { dragOffset = value.translation.height }
            }
            .onEnded { value in
                if value.translation.height > 120 { dismissView() }
                else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { dragOffset = 0 }
                }
            }
    }

    private func dismissView() {
        withAnimation(.easeOut(duration: 0.22)) {
            dragOffset = 0
            isPresented = false
        }
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// 「更多」按钮：弹出歌曲操作菜单
struct SongMoreButton: View {
    let song: Song?
    @State private var isPresented = false

    var body: some View {
        Button {
            Haptics.tap()
            isPresented = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 36).contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.9))
        .sheet(isPresented: $isPresented) {
            if let song {
                SongSheetContainer(song: song)
            }
        }
    }
}

/// 系统音量条：MPVolumeView 是唯一公开可行的入口
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.showsRouteButton = false
        return view
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
