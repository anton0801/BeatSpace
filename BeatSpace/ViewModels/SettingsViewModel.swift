import Foundation
import SwiftUI
import UserNotifications

final class SettingsViewModel: ObservableObject {
    // Theme
    @Published var theme: NeonTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: StorageKeys.theme) }
    }

    enum SchemeMode: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    @Published var schemeMode: SchemeMode {
        didSet { UserDefaults.standard.set(schemeMode.rawValue, forKey: StorageKeys.colorScheme) }
    }

    var colorScheme: ColorScheme? {
        switch schemeMode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    // Equalizer
    @Published var equalizer: EqualizerSettings {
        didSet { Persistence.save(equalizer, key: StorageKeys.equalizer) }
    }

    // Notifications
    @Published var notifNewTrack: Bool {
        didSet {
            UserDefaults.standard.set(notifNewTrack, forKey: StorageKeys.notifNewTrack)
            updateNotifications()
        }
    }
    @Published var notifMix: Bool {
        didSet {
            UserDefaults.standard.set(notifMix, forKey: StorageKeys.notifMix)
            updateNotifications()
        }
    }
    @Published var notifReminder: Bool {
        didSet {
            UserDefaults.standard.set(notifReminder, forKey: StorageKeys.notifReminder)
            updateNotifications()
        }
    }

    // Sound
    enum SoundQuality: String, CaseIterable, Identifiable {
        case standard, high, lossless
        var id: String { rawValue }
        var title: String {
            switch self {
            case .standard: return "Standard (128 kbps)"
            case .high:     return "High (256 kbps)"
            case .lossless: return "Lossless (FLAC)"
            }
        }
    }

    @Published var soundQuality: SoundQuality {
        didSet { UserDefaults.standard.set(soundQuality.rawValue, forKey: StorageKeys.soundQuality) }
    }

    @Published var autoplay: Bool {
        didSet { UserDefaults.standard.set(autoplay, forKey: StorageKeys.autoplay) }
    }
    @Published var crossfade: Bool {
        didSet { UserDefaults.standard.set(crossfade, forKey: StorageKeys.crossfade) }
    }
    @Published var hapticsOn: Bool {
        didSet { UserDefaults.standard.set(hapticsOn, forKey: StorageKeys.hapticsOn) }
    }

    @Published var notifPermissionGranted: Bool = false

    init() {
        // Theme
        if let raw = UserDefaults.standard.string(forKey: StorageKeys.theme),
           let t = NeonTheme(rawValue: raw) {
            theme = t
        } else {
            theme = .purple
        }
        if let raw = UserDefaults.standard.string(forKey: StorageKeys.colorScheme),
           let m = SchemeMode(rawValue: raw) {
            schemeMode = m
        } else {
            schemeMode = .dark
        }

        // Equalizer
        if let eq = Persistence.load(EqualizerSettings.self, key: StorageKeys.equalizer) {
            equalizer = eq
        } else {
            equalizer = EqualizerSettings.flat
        }

        // Notifications
        let defaults = UserDefaults.standard
        // Seed defaults first time
        if defaults.object(forKey: StorageKeys.notifNewTrack) == nil { defaults.set(true, forKey: StorageKeys.notifNewTrack) }
        if defaults.object(forKey: StorageKeys.notifMix) == nil { defaults.set(true, forKey: StorageKeys.notifMix) }
        if defaults.object(forKey: StorageKeys.notifReminder) == nil { defaults.set(false, forKey: StorageKeys.notifReminder) }
        notifNewTrack = defaults.bool(forKey: StorageKeys.notifNewTrack)
        notifMix = defaults.bool(forKey: StorageKeys.notifMix)
        notifReminder = defaults.bool(forKey: StorageKeys.notifReminder)

        // Sound
        if let raw = defaults.string(forKey: StorageKeys.soundQuality),
           let q = SoundQuality(rawValue: raw) {
            soundQuality = q
        } else {
            soundQuality = .high
        }
        if defaults.object(forKey: StorageKeys.autoplay) == nil { defaults.set(true, forKey: StorageKeys.autoplay) }
        if defaults.object(forKey: StorageKeys.crossfade) == nil { defaults.set(false, forKey: StorageKeys.crossfade) }
        if defaults.object(forKey: StorageKeys.hapticsOn) == nil { defaults.set(true, forKey: StorageKeys.hapticsOn) }
        autoplay = defaults.bool(forKey: StorageKeys.autoplay)
        crossfade = defaults.bool(forKey: StorageKeys.crossfade)
        hapticsOn = defaults.bool(forKey: StorageKeys.hapticsOn)

        checkNotificationPermission()
    }

    // MARK: - Theme

    func setTheme(_ t: NeonTheme) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            theme = t
        }
    }

    func setSchemeMode(_ m: SchemeMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            schemeMode = m
        }
    }

    // MARK: - Equalizer

    func setEQBand(_ band: Int, value: Double) {
        var eq = equalizer
        switch band {
        case 0: eq.bass = value
        case 1: eq.lowMid = value
        case 2: eq.mid = value
        case 3: eq.highMid = value
        case 4: eq.treble = value
        default: break
        }
        equalizer = eq
    }

    func resetEQ() {
        equalizer = .flat
    }

    func applyPreset(_ preset: EqualizerSettings.Preset) {
        equalizer = EqualizerSettings.from(preset: preset)
    }

    // MARK: - Notifications

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notifPermissionGranted = (settings.authorizationStatus == .authorized ||
                                                settings.authorizationStatus == .provisional)
            }
        }
    }

    func requestNotificationPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.notifPermissionGranted = granted
                self?.updateNotifications()
                completion?(granted)
            }
        }
    }

    func updateNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard notifPermissionGranted else { return }

        if notifNewTrack {
            let content = UNMutableNotificationContent()
            content.title = "New Tracks Waiting 🎵"
            content.body = "Fresh drops in your mood channels — tap to listen."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 8, repeats: true)
            let req = UNNotificationRequest(identifier: "bs.new", content: content, trigger: trigger)
            center.add(req)
        }

        if notifMix {
            let content = UNMutableNotificationContent()
            content.title = "Your Smart Mix is Ready ✨"
            content.body = "AI tuned a new session to your vibe."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 9
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "bs.mix", content: content, trigger: trigger)
            center.add(req)
        }

        if notifReminder {
            let content = UNMutableNotificationContent()
            content.title = "Keep the streak 🔥"
            content.body = "Tune in today to extend your listening streak."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 20
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "bs.reminder", content: content, trigger: trigger)
            center.add(req)
        }
    }

    // MARK: - Clear cache / reset

    func clearCache() {
        Persistence.remove(key: StorageKeys.activity)
        Persistence.remove(key: StorageKeys.notifications)
    }

    func resetAllData() {
        [StorageKeys.tracks,
         StorageKeys.playlists,
         StorageKeys.favorites,
         StorageKeys.downloads,
         StorageKeys.activity,
         StorageKeys.notifications,
         StorageKeys.listenedSeconds,
         StorageKeys.moodCounts,
         StorageKeys.equalizer].forEach { Persistence.remove(key: $0) }
    }
}

struct EqualizerSettings: Codable, Equatable {
    var bass: Double
    var lowMid: Double
    var mid: Double
    var highMid: Double
    var treble: Double

    static let flat = EqualizerSettings(bass: 0, lowMid: 0, mid: 0, highMid: 0, treble: 0)

    enum Preset: String, CaseIterable, Identifiable {
        case flat, bassBoost, vocal, electronic, acoustic, party
        var id: String { rawValue }
        var title: String {
            switch self {
            case .flat:       return "Flat"
            case .bassBoost:  return "Bass Boost"
            case .vocal:      return "Vocal"
            case .electronic: return "Electronic"
            case .acoustic:   return "Acoustic"
            case .party:      return "Party"
            }
        }
    }

    static func from(preset: Preset) -> EqualizerSettings {
        switch preset {
        case .flat:       return .flat
        case .bassBoost:  return EqualizerSettings(bass: 8, lowMid: 5, mid: 0, highMid: -2, treble: -1)
        case .vocal:      return EqualizerSettings(bass: -2, lowMid: 1, mid: 5, highMid: 4, treble: 2)
        case .electronic: return EqualizerSettings(bass: 6, lowMid: 2, mid: -1, highMid: 3, treble: 6)
        case .acoustic:   return EqualizerSettings(bass: 3, lowMid: 3, mid: 4, highMid: 2, treble: 2)
        case .party:      return EqualizerSettings(bass: 7, lowMid: 3, mid: 2, highMid: 5, treble: 6)
        }
    }

    var bands: [Double] { [bass, lowMid, mid, highMid, treble] }
    static let labels = ["60Hz", "250Hz", "1kHz", "4kHz", "12kHz"]
}
