import Foundation
import SwiftUI

final class MoodViewModel: ObservableObject {
    @Published var current: Mood {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: StorageKeys.currentMood)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: StorageKeys.currentMood),
           let m = Mood(rawValue: raw) {
            self.current = m
        } else {
            self.current = .chill
        }
    }

    func setMood(_ mood: Mood) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            current = mood
        }
        // Track mood usage
        var counts = Persistence.load([String: Int].self, key: StorageKeys.moodCounts) ?? [:]
        counts[mood.rawValue, default: 0] += 1
        Persistence.save(counts, key: StorageKeys.moodCounts)
    }

    var moodCounts: [String: Int] {
        Persistence.load([String: Int].self, key: StorageKeys.moodCounts) ?? [:]
    }
}
