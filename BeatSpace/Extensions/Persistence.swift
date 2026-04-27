import Foundation

enum Persistence {
    static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

enum StorageKeys {
    static let user = "bs.user"
    static let isAuthed = "bs.isAuthed"
    static let tracks = "bs.tracks.v2"
    static let playlists = "bs.playlists"
    static let favorites = "bs.favorites"
    static let downloads = "bs.downloads"
    static let activity = "bs.activity"
    static let notifications = "bs.notifications"
    static let currentMood = "bs.currentMood"
    static let theme = "bs.theme"
    static let colorScheme = "bs.colorScheme"
    static let equalizer = "bs.eq"
    static let sleepMinutes = "bs.sleepMinutes"
    static let listenedSeconds = "bs.listenedSeconds"
    static let moodCounts = "bs.moodCounts"
    static let notifNewTrack = "bs.notif.newTrack"
    static let notifMix = "bs.notif.mix"
    static let notifReminder = "bs.notif.reminder"
    static let soundQuality = "bs.soundQuality"
    static let autoplay = "bs.autoplay"
    static let crossfade = "bs.crossfade"
    static let hapticsOn = "bs.haptics"
}
