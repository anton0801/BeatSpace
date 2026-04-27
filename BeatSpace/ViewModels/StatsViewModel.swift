import Foundation
import SwiftUI

final class StatsViewModel: ObservableObject {
    @Published var activity: [ActivityItem] = []
    @Published var notifications: [NotiItem] = []
    private var didSeed = false

    init() {
        if let saved = Persistence.load([ActivityItem].self, key: StorageKeys.activity), !saved.isEmpty {
            self.activity = saved
            didSeed = true
        }
        if let saved = Persistence.load([NotiItem].self, key: StorageKeys.notifications), !saved.isEmpty {
            self.notifications = saved
        } else {
            self.notifications = SeedData.initialNotifications()
            Persistence.save(notifications, key: StorageKeys.notifications)
        }
    }

    func seedIfNeeded(tracks: [Track]) {
        guard !didSeed else { return }
        activity = SeedData.initialActivity(tracks: tracks)
        Persistence.save(activity, key: StorageKeys.activity)
        didSeed = true
    }

    // MARK: - Activity

    func logPlay(track: Track, seconds: Int) {
        let item = ActivityItem(
            id: UUID(),
            trackTitle: track.title,
            artist: track.artist,
            moodRaw: track.mood.rawValue,
            playedAt: Date(),
            durationListened: seconds
        )
        activity.insert(item, at: 0)
        if activity.count > 100 { activity = Array(activity.prefix(100)) }
        Persistence.save(activity, key: StorageKeys.activity)
    }

    func clearActivity() {
        activity = []
        Persistence.save(activity, key: StorageKeys.activity)
    }

    // MARK: - Stats

    var totalListenedSeconds: Int {
        UserDefaults.standard.integer(forKey: StorageKeys.listenedSeconds) + activity.reduce(0) { $0 + $1.durationListened }
    }

    var totalListenedFormatted: String {
        let total = totalListenedSeconds
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var tracksPlayed: Int { activity.count }

    var topMood: Mood? {
        let counts = Dictionary(grouping: activity, by: { $0.moodRaw }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value }).flatMap { Mood(rawValue: $0.key) }
    }

    var moodBreakdown: [(Mood, Int)] {
        let counts = Dictionary(grouping: activity, by: { $0.moodRaw }).mapValues { $0.count }
        return Mood.allCases.map { ($0, counts[$0.rawValue] ?? 0) }
    }

    var streakDays: Int {
        let cal = Calendar.current
        let days = Set(activity.map { cal.startOfDay(for: $0.playedAt) })
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        while days.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    // MARK: - Notifications

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        Persistence.save(notifications, key: StorageKeys.notifications)
    }

    func markRead(_ id: UUID) {
        if let i = notifications.firstIndex(where: { $0.id == id }) {
            notifications[i].isRead = true
            Persistence.save(notifications, key: StorageKeys.notifications)
        }
    }

    func deleteNotification(_ id: UUID) {
        notifications.removeAll { $0.id == id }
        Persistence.save(notifications, key: StorageKeys.notifications)
    }

    func clearAllNotifications() {
        notifications = []
        Persistence.save(notifications, key: StorageKeys.notifications)
    }

    func addNotification(title: String, body: String, type: String = "reminder") {
        let n = NotiItem(id: UUID(), title: title, body: body, date: Date(), isRead: false, type: type)
        notifications.insert(n, at: 0)
        Persistence.save(notifications, key: StorageKeys.notifications)
    }
}
