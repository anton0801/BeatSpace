import Foundation

enum SeedData {

    static func tracks() -> [Track] {
        // Each tuple: title, artist, album, mood, duration, bpm, genre, coverHex, audioFileName
        // audioFileName is the .mp3 to load from Resources/Audio/ (without extension).
        // If the file is missing, the player falls back to a simulated timer.
        let raw: [(String, String, String, Mood, Int, Int, String, [String], String)] = [
            // Happy
            ("Golden Streets",      "Mila Ray",        "Sunside",        .happy, 204, 118, "Pop",       ["FFB347", "FF5A78"], "golden_streets"),
            ("Citrus Sky",          "The Orangewave",  "Open Windows",   .happy, 186, 124, "Indie Pop", ["FFD36E", "FF7C9A"], "citrus_sky"),
            ("Summer Hologram",     "Nova Stripes",    "Holo",           .happy, 222, 120, "Synth",     ["FFA255", "FF4DA6"], "summer_hologram"),
            ("Neon Laughter",       "Juno Park",       "Bright Side",    .happy, 198, 126, "Pop",       ["FFCF4E", "FF4D8B"], "neon_laughter"),

            // Chill
            ("Coral Drift",         "Solene",          "Tide Pools",     .chill, 258, 84,  "Lo-Fi",     ["43C6CB", "7069F0"], "coral_drift"),
            ("Paper Lanterns",      "Okinawa Blue",    "Calm Streets",   .chill, 244, 78,  "Ambient",   ["5AC8D4", "6A5FE6"], "paper_lanterns"),
            ("Slow Light",          "Miso",            "Afterhours",     .chill, 270, 72,  "Lo-Fi",     ["38A8B3", "8276F2"], "slow_light"),
            ("Velvet Hours",        "Kira Lune",       "Midnight Tea",   .chill, 228, 80,  "Jazz",      ["66D4D6", "7A6AF3"], "velvet_hours"),

            // Focus
            ("Cortex",              "Array Theory",    "Deep Work",      .focus, 312, 90,  "Electronic",["4C8EFF", "9A3EF0"], "cortex"),
            ("Paper & Ink",         "Mariko Azure",    "Studies",        .focus, 294, 86,  "Ambient",   ["3E7AFF", "8630E8"], "paper_and_ink"),
            ("Glass Forest",        "Orbiter",         "Signal",         .focus, 336, 92,  "Electronic",["5190FF", "A845F8"], "glass_forest"),
            ("Quiet Engine",        "Loom",            "Desk Lamp",      .focus, 282, 84,  "Minimal",   ["3B6DE8", "7D2AD6"], "quiet_engine"),

            // Energy
            ("Afterburn",           "Circuit Red",     "Overdrive",      .energy,216, 144, "Electronic",["FF4848", "FF9520"], "afterburn"),
            ("Full Throttle",       "Pulse Drone",     "RPM",            .energy,198, 150, "House",     ["FF5555", "FFA840"], "full_throttle"),
            ("Voltage",             "Neon Tigers",     "High Wire",      .energy,204, 138, "Synthwave", ["FF3A3A", "FF8418"], "voltage"),
            ("Red Line",            "Kite Engine",     "Thrust",         .energy,192, 156, "Techno",    ["FF4C4C", "FF9530"], "red_line"),

            // Sad
            ("Paper Rain",          "Ode Glass",       "Quiet Months",   .sad,   258, 68,  "Indie",     ["5A67BF", "242C73"], "paper_rain"),
            ("Hollow Street",       "Ayumi Grey",      "Empty Rooms",    .sad,   276, 64,  "Piano",     ["5766B5", "1F2670"], "quiet_engine"),
            ("Blue Ceiling",        "Mauve",           "Stargaze",       .sad,   240, 72,  "Ambient",   ["606FC0", "2A327A"], "blue_ceiling"),
            ("Letter Never Sent",   "Winter Fields",   "Snow",           .sad,   252, 70,  "Piano",     ["5466B4", "232B72"], "citrus_sky")
        ]

        return raw.map {
            Track(
                id: UUID(),
                title: $0.0,
                artist: $0.1,
                album: $0.2,
                mood: $0.3,
                durationSeconds: $0.4,
                bpm: $0.5,
                genre: $0.6,
                coverColorsHex: $0.7,
                isDownloaded: false,
                audioFileName: $0.8
            )
        }
    }

    static func systemPlaylists(from tracks: [Track]) -> [Playlist] {
        let byMood: [Mood: [Track]] = Dictionary(grouping: tracks, by: { $0.mood })

        var result: [Playlist] = []
        for mood in Mood.allCases {
            let ids = (byMood[mood] ?? []).map { $0.id }
            result.append(Playlist(
                id: UUID(),
                title: "\(mood.title) Waves",
                desc: mood.subtitle,
                trackIds: ids,
                createdAt: Date(),
                moodRaw: mood.rawValue,
                isSystem: true
            ))
        }
        // Smart Mix — cross-mood
        let smartIds = tracks.shuffled().prefix(8).map { $0.id }
        result.append(Playlist(
            id: UUID(),
            title: "Smart Mix",
            desc: "AI-curated for your vibe right now",
            trackIds: Array(smartIds),
            createdAt: Date(),
            moodRaw: nil,
            isSystem: true
        ))
        return result
    }

    static func initialNotifications() -> [NotiItem] {
        [
            NotiItem(id: UUID(), title: "New Track Drop 🎵", body: "Neon Laughter by Juno Park just landed in Happy Waves.", date: Date().addingTimeInterval(-3600), isRead: false, type: "new_track"),
            NotiItem(id: UUID(), title: "Smart Mix Ready ✨", body: "Your personalized mix for today is waiting.", date: Date().addingTimeInterval(-7200), isRead: false, type: "mix"),
            NotiItem(id: UUID(), title: "Keep the streak 🔥", body: "You listened 3 days in a row — tune in today to extend it.", date: Date().addingTimeInterval(-26000), isRead: true, type: "reminder")
        ]
    }

    static func initialActivity(tracks: [Track]) -> [ActivityItem] {
        tracks.prefix(6).enumerated().map { idx, t in
            ActivityItem(
                id: UUID(),
                trackTitle: t.title,
                artist: t.artist,
                moodRaw: t.mood.rawValue,
                playedAt: Date().addingTimeInterval(TimeInterval(-3600 * (idx + 1))),
                durationListened: t.durationSeconds - idx * 8
            )
        }
    }
}
