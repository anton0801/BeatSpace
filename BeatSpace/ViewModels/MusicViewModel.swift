import Foundation
import SwiftUI

final class MusicViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var favorites: Set<UUID> = []
    @Published var downloads: Set<UUID> = []

    init() {
        if let saved = Persistence.load([Track].self, key: StorageKeys.tracks), !saved.isEmpty {
            self.tracks = saved
        } else {
            self.tracks = SeedData.tracks()
            Persistence.save(tracks, key: StorageKeys.tracks)
        }

        if let favs = Persistence.load([UUID].self, key: StorageKeys.favorites) {
            self.favorites = Set(favs)
        }
        if let dls = Persistence.load([UUID].self, key: StorageKeys.downloads) {
            self.downloads = Set(dls)
            // Sync flag
            for i in tracks.indices { tracks[i].isDownloaded = downloads.contains(tracks[i].id) }
        }
    }

    // MARK: - Queries

    func track(by id: UUID) -> Track? { tracks.first { $0.id == id } }

    func tracks(for mood: Mood) -> [Track] { tracks.filter { $0.mood == mood } }

    func search(_ q: String) -> [Track] {
        let query = q.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return tracks }
        return tracks.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.lowercased().contains(query) ||
            $0.album.lowercased().contains(query) ||
            $0.genre.lowercased().contains(query)
        }
    }

    func recommended(for mood: Mood?, limit: Int = 6) -> [Track] {
        // Deterministic order - same mood + same tracks = same result.
        // Otherwise the list reshuffles every time SwiftUI re-renders body
        // (which happens every second while the player ticks).
        let seedString = (mood?.rawValue ?? "all")
        let seed = seedString.hashValue

        let scored: [(Track, Int)] = tracks.map { t in
            // Stable per-track score: combines track id hash with seed.
            // Tracks of the chosen mood get a heavy boost so they rank first.
            var score = t.id.hashValue ^ seed
            if let m = mood, t.mood == m { score = score | (1 << 30) }
            return (t, score)
        }
        let sorted = scored.sorted { $0.1 > $1.1 }.map { $0.0 }
        return Array(sorted.prefix(limit))
    }

    var favoriteTracks: [Track] { tracks.filter { favorites.contains($0.id) } }
    var downloadedTracks: [Track] { tracks.filter { downloads.contains($0.id) } }

    // MARK: - Favorites

    func isFavorite(_ id: UUID) -> Bool { favorites.contains(id) }

    func toggleFavorite(_ id: UUID) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
        Persistence.save(Array(favorites), key: StorageKeys.favorites)
    }

    // MARK: - Downloads

    func isDownloaded(_ id: UUID) -> Bool { downloads.contains(id) }

    func toggleDownload(_ id: UUID) {
        if downloads.contains(id) { downloads.remove(id) } else { downloads.insert(id) }
        if let i = tracks.firstIndex(where: { $0.id == id }) {
            tracks[i].isDownloaded = downloads.contains(id)
        }
        Persistence.save(Array(downloads), key: StorageKeys.downloads)
        Persistence.save(tracks, key: StorageKeys.tracks)
    }

    func removeDownload(_ id: UUID) {
        downloads.remove(id)
        if let i = tracks.firstIndex(where: { $0.id == id }) {
            tracks[i].isDownloaded = false
        }
        Persistence.save(Array(downloads), key: StorageKeys.downloads)
        Persistence.save(tracks, key: StorageKeys.tracks)
    }

    // MARK: - Categories for Discover

    struct Category: Identifiable, Hashable {
        var id: String { title }
        let title: String
        let symbol: String
        let colors: [Color]
        let genre: String?
        let mood: Mood?

        static func == (lhs: Category, rhs: Category) -> Bool { lhs.title == rhs.title }
        func hash(into hasher: inout Hasher) { hasher.combine(title) }
    }

    let discoverCategories: [Category] = [
        .init(title: "Lo-Fi",     symbol: "headphones",         colors: [Color(hex: "43C6CB")!, Color(hex: "7069F0")!], genre: "Lo-Fi",      mood: nil),
        .init(title: "Synthwave", symbol: "waveform",           colors: [Color(hex: "FF3A3A")!, Color(hex: "FF8418")!], genre: "Synthwave", mood: nil),
        .init(title: "Ambient",   symbol: "cloud.fill",         colors: [Color(hex: "3E7AFF")!, Color(hex: "8630E8")!], genre: "Ambient",   mood: nil),
        .init(title: "Pop",       symbol: "music.note",         colors: [Color(hex: "FFB347")!, Color(hex: "FF5A78")!], genre: "Pop",       mood: nil),
        .init(title: "Electronic",symbol: "bolt.circle.fill",   colors: [Color(hex: "4C8EFF")!, Color(hex: "9A3EF0")!], genre: "Electronic",mood: nil),
        .init(title: "Piano",     symbol: "pianokeys",          colors: [Color(hex: "5766B5")!, Color(hex: "1F2670")!], genre: "Piano",     mood: nil),
    ]

    func tracks(inGenre genre: String) -> [Track] {
        tracks.filter { $0.genre.lowercased() == genre.lowercased() }
    }
}
