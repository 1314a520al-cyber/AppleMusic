//
//  NowPlayingView.swift
//  AppleMusic
//
//  全屏播放页（苹果音乐样式）。
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
    @State private var showVolume = false

    private var song: Song? { player.currentSong }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = min(geo.size.width - 64, 340)
            ZStack {
                backgroundLayer
                contentLayer(artworkSize: artworkSize)
            }
            .offset(y: dragOffset)
            .gesture(dismissGesture)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showLyrics) {
            LyricsSheet().environmentObject(player).environmentObject(clock)
        }
        .sheet(isPresented: $showQueue) {
            QueueSheet().environmentObject(player)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            if let url = song?.coverURL {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                        .blur(radius: 60).opacity(0.35)
                } placeholder: { Color.clear }
                .ignoresSafeArea()
            }
            LinearGradient(
                colors: [Color.black.opacity(0.06), Color.clear, Color.black.opacity(0.10)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.5), value: song?.identityKey)
    }

    private func contentLayer(artworkSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button { Haptics.tap(); dismissView() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40).contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.9))

                Spacer()

                if let notice = player.notice {
                    Text(notice).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                }

                Spacer()

                Button { Haptics.tap(); showQueue = true } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40).contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.9))
            }
            .padding(.horizontal, 12).padding(.top, 8)

            Spacer(minLength: 8)

            CoverArtView(url: song?.coverURL, size: artworkSize, cornerRadius: 10)
                .shadow(color: .black.opacity(0.28), radius: 28, y: 14)
                .scaleEffect(player.isPlaying ? 1.0 : 0.94)
                .animation(.spring(response: 0.42, dampingFraction: 0.82), value: player.isPlaying)

            Spacer(minLength: 16)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(song?.name ?? "未在播放")
                        .font(.system(size: 20, weight: .semibold)).lineLimit(1)
                    Text(song?.artists ?? "")
                        .font(.system(size: 16)).foregroundStyle(Color.accentColor).lineLimit(1)
                }
                Spacer(minLength: 0)
                if let song {
                    Button {
                        Haptics.tap()
                        let liked = favorites.toggle(song)
                        ToastCenter.shared.show(liked ? "已收藏" : "已取消收藏",
                                                icon: liked ? "heart.fill" : "heart")
                    } label: {
                        Image(systemName: favorites.contains(song) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(favorites.contains(song) ? Color.red : Color.secondary)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))
                }
            }
            .padding(.horizontal, 28)

            progressBar.padding(.horizontal, 28).padding(.top, 14)
            playbackControls.padding(.horizontal, 32).padding(.top, 18)
            bottomBar.padding(.horizontal, 32).padding(.top, 20)

            Spacer(minLength: 24)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let width = geo.size.width
                let duration = clock.duration > 0 ? clock.duration : 1
                let current = isScrubbing ? scrubValue : clock.progress
                let ratio = max(0, min(1, current / duration))

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.16)).frame(height: isScrubbing ? 7 : 4)
                    Capsule().fill(Color.primary.opacity(0.75))
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

    private var playbackControls: some View {
        HStack(spacing: 0) {
            Button { Haptics.tap(); player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26)).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity).frame(height: 60).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))

            Button { player.togglePlayPause() } label: {
                ZStack {
                    if player.isBuffering { ProgressView().scaleEffect(1.1) }
                    else { PlayPauseIcon(isPlaying: player.isPlaying, size: 34).foregroundStyle(.primary) }
                }
                .frame(maxWidth: .infinity).frame(height: 60).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))

            Button { Haptics.tap(); player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26)).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity).frame(height: 60).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.88))
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button { Haptics.tap(); showVolume.toggle() } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 17)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).frame(height: 44).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            Button {
                player.togglePlayMode()
                ToastCenter.shared.show(player.playMode.title, icon: player.playMode.icon)
            } label: {
                Image(systemName: player.playMode.icon)
                    .font(.system(size: 17)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).frame(height: 44).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))

            if settings.showLyricsInPlayer {
                Button { Haptics.tap(); showLyrics = true } label: {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 17)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).frame(height: 44).contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.9))
            }

            Button {
                Haptics.tap()
                if let song {
                    Task {
                        let result = await DownloadManager.download(song: song)
                        await MainActor.run {
                            switch result {
                            case .success: ToastCenter.shared.success("已下载")
                            case .failure(let error): ToastCenter.shared.error(error.localizedDescription)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 17)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).frame(height: 44).contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))
        }
        .overlay(alignment: .topLeading) {
            if showVolume {
                SystemVolumeSlider()
                    .frame(width: 200, height: 34)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule().fill(Color(uiColor: .secondarySystemBackground))
                    }
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .offset(y: -46)
            }
        }
    }

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

/// 系统音量条：MPVolumeView 是唯一公开可行的入口
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.showsRouteButton = false
        return view
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
