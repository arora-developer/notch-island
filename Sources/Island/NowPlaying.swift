import AppKit
import Combine

enum Player: String {
    case spotify = "Spotify"
    case music = "Music"

    var bundleID: String {
        switch self {
        case .spotify: return "com.spotify.client"
        case .music: return "com.apple.Music"
        }
    }
}

struct NowPlayingTrack: Equatable {
    var title: String
    var artist: String
    var artworkURL: String
    var position: Double
    var duration: Double
    var artwork: NSImage?
}

/// Now-playing info and transport controls for Music and Spotify, via AppleScript.
/// Polled on a background queue; the first use triggers macOS's one-time "Island wants to control Spotify" prompt.
final class NowPlayingController: ObservableObject {
    @Published private(set) var track: NowPlayingTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var player: Player?

    var progress: Double {
        guard let t = track, t.duration > 0 else { return 0 }
        return min(1, max(0, t.position / t.duration))
    }

    var pollInterval: TimeInterval = 2 {
        didSet { if timer != nil { restartTimer() } }
    }

    private var timer: Timer?
    private let queue = DispatchQueue(label: "island.nowplaying", qos: .utility)
    private var artworkKey = ""

    func start() {
        restartTimer()
        poll()
    }

    private func restartTimer() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in self?.poll() }
        t.tolerance = 0.3
        timer = t
    }

    private func runningPlayer() -> Player? {
        let apps = NSWorkspace.shared.runningApplications
        for p in [Player.spotify, .music] where apps.contains(where: { $0.bundleIdentifier == p.bundleID }) {
            return p
        }
        return nil
    }

    func poll() {
        guard let p = runningPlayer() else {
            apply(player: nil, info: nil)
            return
        }
        queue.async { [weak self] in
            let out = AppleScriptRunner.run(NowPlayingController.infoScript(for: p))
            DispatchQueue.main.async { self?.apply(player: p, info: out) }
        }
    }

    private func apply(player p: Player?, info: String?) {
        if player != p { player = p }
        guard let p, let info, !info.isEmpty, info != "stopped" else {
            if track != nil { track = nil }
            if isPlaying { isPlaying = false }
            artworkKey = ""
            return
        }
        let parts = info.components(separatedBy: "\n")
        guard parts.count >= 6 else { return }
        var t = NowPlayingTrack(title: parts[0],
                                artist: parts[1],
                                artworkURL: parts[3],
                                position: Double(parts[4].replacingOccurrences(of: ",", with: ".")) ?? 0,
                                duration: Double(parts[5].replacingOccurrences(of: ",", with: ".")) ?? 0,
                                artwork: track?.artwork)
        let playing = parts[2].lowercased().contains("playing")
        if playing != isPlaying { isPlaying = playing }

        let key = "\(p.rawValue)|\(t.title)|\(t.artist)"
        if key != artworkKey {
            artworkKey = key
            t.artwork = nil
            fetchArtwork(for: p, track: t, key: key)
        }
        if t != track { track = t }
    }

    private func fetchArtwork(for p: Player, track t: NowPlayingTrack, key: String) {
        switch p {
        case .spotify:
            guard let url = URL(string: t.artworkURL) else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    guard let self, self.artworkKey == key else { return }
                    self.track?.artwork = image
                }
            }.resume()
        case .music:
            // Raw image data only comes back cleanly through NSAppleScript, which wants the main thread.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self, self.artworkKey == key else { return }
                let script = NSAppleScript(source: "tell application \"Music\" to get data of artwork 1 of current track")
                var error: NSDictionary?
                if let descriptor = script?.executeAndReturnError(&error), let image = NSImage(data: descriptor.data) {
                    self.track?.artwork = image
                }
            }
        }
    }

    // MARK: - Transport

    func playPause() { command("playpause") }
    func next() { command("next track") }
    func previous() { command("previous track") }

    private func command(_ c: String) {
        guard let p = player else { return }
        queue.async { [weak self] in
            _ = AppleScriptRunner.run("tell application \"\(p.rawValue)\" to \(c)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self?.poll() }
        }
    }

    // MARK: - Scripts

    static func infoScript(for p: Player) -> String {
        switch p {
        case .spotify:
            return """
            tell application "Spotify"
                if player state is stopped then return "stopped"
                set t to current track
                return (name of t) & linefeed & (artist of t) & linefeed & (player state as text) & linefeed & (artwork url of t) & linefeed & (player position as text) & linefeed & ((duration of t) / 1000 as text)
            end tell
            """
        case .music:
            return """
            tell application "Music"
                if player state is stopped then return "stopped"
                set t to current track
                return (name of t) & linefeed & (artist of t) & linefeed & (player state as text) & linefeed & "" & linefeed & (player position as text) & linefeed & (duration of t as text)
            end tell
            """
        }
    }
}
