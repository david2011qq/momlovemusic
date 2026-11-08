import SwiftUI

func timeString(_ s: Double) -> String {
    let t = Int(max(0, s.isFinite ? s : 0))
    return String(format: "%d:%02d", t / 60, t % 60)
}

// MARK: - Mini player shown above the tab bar

struct MiniPlayerInset: ViewModifier {
    @EnvironmentObject var player: PlayerManager
    @State private var showFull = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let song = player.current {
                    MiniPlayerBar(song: song) { showFull = true }
                }
            }
            .fullScreenCover(isPresented: $showFull) { PlayerView() }
    }
}

extension View {
    func miniPlayer() -> some View { modifier(MiniPlayerInset()) }
}

/// Progress bar with elapsed time on the left and time left (-m:ss) on the right.
struct ProgressStrip: View {
    @EnvironmentObject var player: PlayerManager
    let color: Color

    var body: some View {
        let progress = player.duration > 0 ? min(max(player.currentTime / player.duration, 0), 1) : 0
        HStack(spacing: 8) {
            Text(timeString(player.currentTime))
                .font(kidFont(12, .bold))
                .monospacedDigit()
                .foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.25))
                    Capsule().fill(color).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
            Text("-" + timeString(player.duration - player.currentTime))
                .font(kidFont(12, .bold))
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }
}

struct MiniPlayerBar: View {
    @EnvironmentObject var player: PlayerManager
    let song: Song
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Text("🎶")
                    .font(.system(size: 26))
                    .frame(width: 48, height: 48)
                    .background(Theme.color(player.index), in: Circle())
                Text(song.title)
                    .font(kidFont(17))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(Theme.color(0))
                }
                .buttonStyle(BounceStyle())
                Button { player.next() } label: {
                    Image(systemName: "forward.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(Theme.color(5))
                }
                .buttonStyle(BounceStyle())
            }
            ProgressStrip(color: Theme.color(player.index))
                .padding(.horizontal, 6)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Full screen player

struct PlayerView: View {
    @EnvironmentObject var library: Library
    @EnvironmentObject var player: PlayerManager
    @Environment(\.dismiss) private var dismiss
    @State private var pulse = false
    @State private var scrubbing = false
    @State private var scrubTime: Double = 0

    private var playingList: Playlist? {
        library.playlists.first { $0.id == player.playingPlaylistID }
    }
    private var accent: Color { Theme.color(playingList?.colorIndex ?? 5) }
    private var shownTime: Double { scrubbing ? scrubTime : player.currentTime }

    var body: some View {
        ZStack {
            LinearGradient(colors: [accent, accent.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(BounceStyle())
                    Spacer()
                    Text(playingList?.name ?? "All Songs")
                        .font(kidFont(22))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Color.clear.frame(width: 38, height: 38)
                }

                Spacer()

                Text(playingList?.emoji ?? "🎵")
                    .font(.system(size: 120))
                    .frame(width: 260, height: 260)
                    .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.2), radius: 12, y: 6))
                    .scaleEffect(player.isPlaying && pulse ? 1.07 : 1.0)

                Text(player.current?.title ?? "")
                    .font(kidFont(28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)

                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { shownTime },
                            set: { scrubTime = $0 }
                        ),
                        in: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            if editing {
                                scrubTime = player.currentTime
                                scrubbing = true
                            } else {
                                player.seek(scrubTime)
                                scrubbing = false
                            }
                        }
                    )
                    .tint(.white)

                    HStack {
                        Text(timeString(shownTime))
                        Spacer()
                        Text("-" + timeString(player.duration - shownTime))
                    }
                    .font(kidFont(16, .bold))
                    .monospacedDigit()
                    .foregroundColor(.white)
                }

                HStack(spacing: 36) {
                    Button { player.previous() } label: {
                        Image(systemName: "backward.circle.fill").font(.system(size: 60))
                    }
                    Button { player.toggle() } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 100))
                    }
                    Button { player.next() } label: {
                        Image(systemName: "forward.circle.fill").font(.system(size: 60))
                    }
                }
                .foregroundColor(.white)
                .buttonStyle(BounceStyle())

                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onChange(of: player.current?.id) { id in
            if id == nil { dismiss() }
        }
    }
}
