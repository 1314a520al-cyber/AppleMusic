//
//  NowPlayingView.swift
//  AppleMusic
//
//  全屏播放页。
//
//  结构（严格对照参考图）：
//    顶部：下拉小把手 + 收起箭头
//    大方形封面（圆角 + 阴影）
//    歌名 / 歌手 + 右侧两个灰色圆形按钮（星标 / 更多）
//    进度条 + 时间（左已播 / 右剩余）
//    上一首 / 播放暂停 / 下一首
//    音量条
//    底部：歌词 / 电台 / 队列
//
//  可选展示「待播清单」列表（设置开关）。
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
    @State private var showMore = false

    private var song: Song? { player.currentSong }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = min(geo.size.width - 56, 360)

            ZStack {
                backgroundLayer

                VStack(spacing: 0) {

                    // 顶部把手 + 收起
                    topHandle

                    Spacer(minLength: 6)

                    // 大封面
                    CoverArtView(url: song?.coverURL, size: artworkSize, cornerRadius: 8)
                        .shadow(color: .black.opacity(0.30), radius: 24, y: 12)
                        .scaleEffect(player.isPlaying ? 1.0 : 0.95)
                        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: player.isPlaying)

                    Spacer(minLength: 18)

                    // 歌名 / 歌手 + 星标 + 更多
                    titleRow
                        .padding(.horizontal, 26)

                    // 进度条
                    progressBar
                        .padding(.horizontal, 26)
                        .padding(.top, 14)

                    // 控制键
                    playbackControls
                        .padding(.horizontal, 30)
                        .padding(.top, 10)

                    // 音量条
                    if settings.showNowPlayingVolume {
                        SystemVolumeSlider()
                            .frame(height: 34)
                            .padding(.horizontal, 26)
                            .padding(.top, 4)
                    }

                    // 底部工具条
                    if settings.showNowPlayingBottomBar {
                        bottomBar
                            .padding(.horizontal, 30)
                            .padding(.top, 6)
                    }

                    Spacer(minLength: 6)
                }
                .offset(y: dragOffset)
                .gesture(dismissGesture)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $showLyrics) {
            LyricsSheet().environmentObject(player).environmentObject(clock)
        }
        .sheet(isPresented: $showQueue) {
            QueueSheet().environmentObject(player)
        }
        .sheet(isPresented: $showMore) {
            if let song {
                SongSheetContainer(song: song)
                    .environmentObject(player)
                    .environmentObject(favorites)
            }
        }
    }

    // MARK: - 顶部把手

    private var topHandle: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color.primary.opacity(0.22))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            HStack {
                Button { Haptics.tap(); dismissView() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.9))

                Spacer()

                if let notice = player.notice {
                    Text(notice)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 占位，保持标题居中
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - 歌名行

    private var titleRow: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(song?.name ?? "未在播放")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song?.artists ?? "")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // 星标
            Button {
                Haptics.tap()
                guard let song else { return }
                let liked = favorites.toggle(song)
                ToastCenter.shared.show(liked ? "已收藏" : "已取消收藏",
                                        icon: liked ? "star.fill" : "star")
            } label: {
                Image(systemName: (song.map { favorites.contains($0) } ?? false) ? "star.fill" : "star")
                    .font(.system(size: 17))
                    .foregroundStyle((song.map { favorites.contains($0) } ?? false)
                                     ? settings.accent.color : Color.primary.opacity(0.8))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.primary.opacity(0.10)))
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            // 更多
            Button {
                Haptics.tap()
                showMore = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.primary.opacity(0.10)))
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))
        }
    }

    // MARK: - 进度条

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                let duration = clock.duration > 0 ? clock.duration : 1
                let current = isScrubbing ? scrubValue : clock.progress
                let ratio = max(0, min(1, current / duration))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.18))
                        .frame(height: isScrubbing ? 7 : 5)

                    Capsule()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: width * CGFloat(ratio), height: isScrubbing ? 7 : 5)

                    // 进度圆点
                    Circle()
                        .fill(Color.primary.opacity(0.9))
                        .frame(width: isScrubbing ? 15 : 11, height: isScrubbing ? 15 : 11)
                        .offset(x: width * CGFloat(ratio) - (isScrubbing ? 7.5 : 5.5))
                }
                .frame(height: 22)
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
            .frame(height: 22)

            HStack {
                Text(timeString(isScrubbing ? scrubValue : clock.progress))
                Spacer()
                Text("−" + timeString(max(0, clock.duration - (isScrubbing ? scrubValue : clock.progress))))
            }
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - 控制键

    private var playbackControls: some View {
        HStack(spacing: 0) {
            Button { Haptics.tap(); player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))

            Button { player.togglePlayPause() } label: {
                ZStack {
                    if player.isBuffering {
                        ProgressView().scaleEffect(1.1)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))

            Button { Haptics.tap(); player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))
        }
    }

    // MARK: - 底部工具条

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button { Haptics.tap(); showLyrics = true } label: {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            Button { Haptics.tap(); showQueue = true } label: {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            Button { Haptics.tap(); showQueue = true } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))
        }
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            Color(uiColor: .systemBackground)

            if let url = song?.coverURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                        .blur(radius: 70)
                        .opacity(0.30)
                } placeholder: { Color.clear }
                .ignoresSafeArea()
            }

            LinearGradient(
                colors: [Color.black.opacity(0.05), Color.clear, Color.black.opacity(0.12)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.5), value: song?.identityKey)
    }

    // MARK: - 手势

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 { dragOffset = value.translation.height }
            }
            .onEnded { value in
                if value.translation.height > 120 {
                    dismissView()
                } else {
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

/// 系统音量条：MPVolumeView 是唯一公开可行的入口
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.showsRouteButton = false
        return view
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
