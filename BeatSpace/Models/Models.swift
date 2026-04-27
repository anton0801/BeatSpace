import Foundation
import SwiftUI

// MARK: - User

struct AppUser: Codable, Equatable {
    var id: UUID
    var name: String
    var email: String
    var xp: Int
    var joinedAt: Date
    var isGuest: Bool
    var isDemo: Bool

    var level: Int { max(1, xp / 100 + 1) }
    var levelTitle: String {
        switch level {
        case 1: return "Beat Rookie"
        case 2: return "Groove Seeker"
        case 3: return "Rhythm Rider"
        case 4: return "Sound Explorer"
        case 5: return "Wave Master"
        default: return "Neon Legend"
        }
    }
    var progressToNext: Double { Double(xp % 100) / 100.0 }

    static var demo: AppUser {
        AppUser(
            id: UUID(),
            name: "Demo Listener",
            email: "demo@beatspace.app",
            xp: 240,
            joinedAt: Date().addingTimeInterval(-60 * 60 * 24 * 14),
            isGuest: false,
            isDemo: true
        )
    }

    static var guest: AppUser {
        AppUser(
            id: UUID(),
            name: "Guest",
            email: "",
            xp: 0,
            joinedAt: Date(),
            isGuest: true,
            isDemo: false
        )
    }
}

// MARK: - Mood

enum Mood: String, CaseIterable, Identifiable, Codable {
    case happy, chill, focus, energy, sad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .happy:  return "Happy"
        case .chill:  return "Chill"
        case .focus:  return "Focus"
        case .energy: return "Energy"
        case .sad:    return "Sad"
        }
    }

    var subtitle: String {
        switch self {
        case .happy:  return "Bright, uplifting grooves"
        case .chill:  return "Soft waves, slow tempo"
        case .focus:  return "Deep flow, no distractions"
        case .energy: return "High BPM, full drive"
        case .sad:    return "Mellow, reflective sounds"
        }
    }

    var symbol: String {
        switch self {
        case .happy:  return "sun.max.fill"
        case .chill:  return "leaf.fill"
        case .focus:  return "brain.head.profile"
        case .energy: return "bolt.fill"
        case .sad:    return "cloud.rain.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .happy:  return [Color(red: 1.00, green: 0.70, blue: 0.20), Color(red: 1.00, green: 0.35, blue: 0.55)]
        case .chill:  return [Color(red: 0.20, green: 0.75, blue: 0.80), Color(red: 0.45, green: 0.40, blue: 0.95)]
        case .focus:  return [Color(red: 0.30, green: 0.55, blue: 1.00), Color(red: 0.60, green: 0.25, blue: 0.95)]
        case .energy: return [Color(red: 1.00, green: 0.35, blue: 0.35), Color(red: 1.00, green: 0.60, blue: 0.10)]
        case .sad:    return [Color(red: 0.35, green: 0.40, blue: 0.75), Color(red: 0.15, green: 0.20, blue: 0.45)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var bpmRange: ClosedRange<Int> {
        switch self {
        case .happy:  return 110...128
        case .chill:  return 72...92
        case .focus:  return 80...100
        case .energy: return 128...160
        case .sad:    return 60...80
        }
    }
}

// MARK: - Track

struct Track: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var artist: String
    var album: String
    var mood: Mood
    var durationSeconds: Int
    var bpm: Int
    var genre: String
    var coverColorsHex: [String]
    var isDownloaded: Bool
    /// Filename (without extension) of the bundled mp3 in Resources/Audio/.
    /// If the file is not present, the player falls back to a simulated timer.
    var audioFileName: String

    var duration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var coverColors: [Color] {
        coverColorsHex.compactMap(Color.init(hex:))
    }

    var coverGradient: LinearGradient {
        let colors = coverColors.isEmpty ? mood.colors : coverColors
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Playlist

struct Playlist: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var desc: String
    var trackIds: [UUID]
    var createdAt: Date
    var moodRaw: String?
    var isSystem: Bool

    var mood: Mood? { moodRaw.flatMap { Mood(rawValue: $0) } }
}

// MARK: - Activity

struct ActivityItem: Codable, Identifiable, Equatable {
    var id: UUID
    var trackTitle: String
    var artist: String
    var moodRaw: String
    var playedAt: Date
    var durationListened: Int

    var mood: Mood? { Mood(rawValue: moodRaw) }
}

// MARK: - Notification Item

struct NotiItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var date: Date
    var isRead: Bool
    var type: String // "new_track", "mix", "reminder"
}

// MARK: - Color Hex init

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let v = UInt64(hex, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
