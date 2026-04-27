import Foundation
import SwiftUI
import Combine
import AVFoundation

final class PlayerViewModel: NSObject, ObservableObject {
    @Published var currentTrack: Track?
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0

    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0 // 0..1
    @Published var elapsed: Int = 0 // seconds
    @Published var shuffle: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Double = 0.7 {
        didSet {
            audioPlayer?.volume = Float(volume)
        }
    }
    @Published var visualizerAmplitude: Double = 0.5

    // Sleep timer
    @Published var sleepMinutes: Int = 0 // 0 = off
    @Published var sleepSecondsLeft: Int = 0
    private var sleepTimer: Timer?

    // Playback
    private var audioPlayer: AVAudioPlayer?
    private var ticker: Timer?
    private var visualizerTicker: Timer?

    enum RepeatMode: String, CaseIterable { case off, all, one
        var symbol: String {
            switch self {
            case .off: return "repeat"
            case .all: return "repeat"
            case .one: return "repeat.1"
            }
        }
    }

    override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("[Player] AudioSession config failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Queue control

    func load(track: Track, queue: [Track]? = nil) {
        let q = queue ?? [track]
        self.queue = q
        self.currentIndex = q.firstIndex(of: track) ?? 0
        self.currentTrack = track
        self.elapsed = 0
        self.progress = 0
        loadAudio(for: track)
        play()
    }

    /// Tries to load the bundled audio file for this track.
    /// If the file isn't bundled, falls back to simulated playback.
    private func loadAudio(for track: Track) {
        audioPlayer?.stop()
        audioPlayer = nil

        // Search both bundle root and Audio/ subdirectory for mp3/m4a/wav.
        // Folder references in Xcode preserve the directory layout in the bundle,
        // so files end up under "Audio/" and need an explicit subdirectory hint.
        let exts = ["mp3", "m4a", "wav"]
        var url: URL?
        for ext in exts {
            if let u = Bundle.main.url(forResource: track.audioFileName, withExtension: ext, subdirectory: "Audio") {
                url = u; break
            }
            if let u = Bundle.main.url(forResource: track.audioFileName, withExtension: ext) {
                url = u; break
            }
        }

        guard let url = url else {
            print("[Player] No bundled audio for '\(track.audioFileName)' — running simulation")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.volume = Float(volume)
            p.numberOfLoops = (repeatMode == .one) ? -1 : 0
            p.isMeteringEnabled = true
            p.prepareToPlay()
            audioPlayer = p
        } catch {
            print("[Player] Failed to load \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    func play() {
        guard currentTrack != nil else { return }
        isPlaying = true
        audioPlayer?.play()
        startTicker()
        startVisualizer()
    }

    func pause() {
        isPlaying = false
        audioPlayer?.pause()
        stopTicker()
    }

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func next() {
        guard !queue.isEmpty else { return }
        if shuffle && queue.count > 1 {
            var newIdx = currentIndex
            while newIdx == currentIndex {
                newIdx = Int.random(in: 0..<queue.count)
            }
            currentIndex = newIdx
        } else {
            if currentIndex + 1 < queue.count {
                currentIndex += 1
            } else if repeatMode == .all {
                currentIndex = 0
            } else {
                pause()
                return
            }
        }
        let t = queue[currentIndex]
        currentTrack = t
        elapsed = 0
        progress = 0
        loadAudio(for: t)
        play()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if elapsed > 3 {
            seek(to: 0)
            return
        }
        if currentIndex - 1 >= 0 {
            currentIndex -= 1
        } else {
            currentIndex = queue.count - 1
        }
        let t = queue[currentIndex]
        currentTrack = t
        elapsed = 0
        progress = 0
        loadAudio(for: t)
        play()
    }

    func seek(to fraction: Double) {
        guard let t = currentTrack else { return }
        let clamped = min(max(fraction, 0), 1)
        progress = clamped
        let target = Double(t.durationSeconds) * clamped
        elapsed = Int(target)
        if let p = audioPlayer {
            p.currentTime = target
        }
    }

    func toggleShuffle() { shuffle.toggle() }

    func cycleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        audioPlayer?.numberOfLoops = (repeatMode == .one) ? -1 : 0
    }

    // MARK: - Sleep timer

    func startSleepTimer(minutes: Int) {
        stopSleepTimer()
        sleepMinutes = minutes
        sleepSecondsLeft = minutes * 60
        UserDefaults.standard.set(minutes, forKey: StorageKeys.sleepMinutes)
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.sleepSecondsLeft > 0 {
                self.sleepSecondsLeft -= 1
            } else {
                self.pause()
                self.stopSleepTimer()
            }
        }
    }

    func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepMinutes = 0
        sleepSecondsLeft = 0
        UserDefaults.standard.set(0, forKey: StorageKeys.sleepMinutes)
    }

    // MARK: - Internal ticking

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let t = self.currentTrack else { return }

            if let p = self.audioPlayer {
                let secs = Int(p.currentTime)
                if secs != self.elapsed {
                    self.elapsed = secs
                    self.progress = p.duration > 0 ? min(1, p.currentTime / p.duration) : 0
                }
            } else {
                // Simulation mode (no real mp3 bundled)
                if self.elapsed < t.durationSeconds {
                    self.elapsed += 1
                    self.progress = Double(self.elapsed) / Double(t.durationSeconds)
                } else {
                    if self.repeatMode == .one {
                        self.elapsed = 0
                        self.progress = 0
                    } else {
                        self.next()
                    }
                    return
                }
            }

            if self.isPlaying {
                var total = UserDefaults.standard.integer(forKey: StorageKeys.listenedSeconds)
                total += 1
                UserDefaults.standard.set(total, forKey: StorageKeys.listenedSeconds)
            }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func startVisualizer() {
        visualizerTicker?.invalidate()
        visualizerTicker = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPlaying {
                if let p = self.audioPlayer {
                    p.updateMeters()
                    let avg = p.averagePower(forChannel: 0)
                    // Map dB (-50...0) to 0.2...1.0
                    let normalized = max(0, min(1, (Double(avg) + 50) / 50))
                    withAnimation(.easeInOut(duration: 0.08)) {
                        self.visualizerAmplitude = max(0.2, normalized)
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.08)) {
                        self.visualizerAmplitude = Double.random(in: 0.3...1.0)
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.visualizerAmplitude = 0.15
                }
            }
        }
    }

    deinit {
        ticker?.invalidate()
        visualizerTicker?.invalidate()
        sleepTimer?.invalidate()
        audioPlayer?.stop()
    }
}

// MARK: - AVAudioPlayerDelegate

extension PlayerViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.repeatMode == .one {
                player.currentTime = 0
                player.play()
                self.elapsed = 0
                self.progress = 0
            } else {
                self.next()
            }
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("[Player] Decode error: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { [weak self] in self?.next() }
    }
}
