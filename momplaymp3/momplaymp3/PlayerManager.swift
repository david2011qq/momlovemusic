import AVFoundation
import MediaPlayer

/// One shared player for the whole app, so only ONE playlist can ever play at a time.
/// Starting a new playlist replaces the current queue.
final class PlayerManager: ObservableObject {
    @Published private(set) var queue: [Song] = []
    @Published private(set) var index = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var playingPlaylistID: UUID?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    var current: Song? { queue.indices.contains(index) ? queue[index] : nil }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds.isFinite ? time.seconds : 0
            if let d = self.player.currentItem?.duration.seconds, d.isFinite {
                self.duration = d
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in
            self?.next()
        }

        setupRemoteCommands()
    }

    // MARK: Controls

    func start(_ songs: [Song], at startIndex: Int = 0, playlistID: UUID?) {
        guard !songs.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        queue = songs
        playingPlaylistID = playlistID
        load(startIndex)
    }

    private func load(_ i: Int) {
        guard queue.indices.contains(i) else { return }
        index = i
        let item = AVPlayerItem(url: Library.fileURL(for: queue[i]))
        player.replaceCurrentItem(with: item)
        currentTime = 0
        duration = 0
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func resume() {
        guard current != nil else { return }
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func toggle() { isPlaying ? pause() : resume() }

    func next() {
        guard !queue.isEmpty else { return }
        load((index + 1) % queue.count) // loops back to the start
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(0)
        } else {
            load((index - 1 + queue.count) % queue.count)
        }
    }

    func seek(_ seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
        updateNowPlaying()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        queue = []
        index = 0
        isPlaying = false
        currentTime = 0
        duration = 0
        playingPlaylistID = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Call before a song is deleted from the library.
    func stopIfQueued(_ songID: UUID) {
        if queue.contains(where: { $0.id == songID }) { stop() }
    }

    func stopIfPlaying(playlist id: UUID) {
        if playingPlaylistID == id { stop() }
    }

    // MARK: Lock screen

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.resume(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
    }

    private func updateNowPlaying() {
        guard let song = current else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: song.title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }
}
