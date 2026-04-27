import Foundation
import Combine

final class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    private var didSeed = false

    init() {
        if let saved = Persistence.load([Playlist].self, key: StorageKeys.playlists), !saved.isEmpty {
            self.playlists = saved
            didSeed = true
        }
    }

    func seedIfNeeded(tracks: [Track]) {
        guard !didSeed else { return }
        playlists = SeedData.systemPlaylists(from: tracks)
        Persistence.save(playlists, key: StorageKeys.playlists)
        didSeed = true
    }

    func userPlaylists() -> [Playlist] { playlists.filter { !$0.isSystem } }
    func systemPlaylists() -> [Playlist] { playlists.filter { $0.isSystem } }

    func create(title: String, desc: String, trackIds: [UUID] = []) -> Playlist {
        let p = Playlist(
            id: UUID(),
            title: title,
            desc: desc,
            trackIds: trackIds,
            createdAt: Date(),
            moodRaw: nil,
            isSystem: false
        )
        playlists.insert(p, at: 0)
        save()
        return p
    }

    func delete(_ id: UUID) {
        playlists.removeAll { $0.id == id && !$0.isSystem }
        save()
    }

    func addTrack(_ trackId: UUID, to playlistId: UUID) {
        guard let i = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        if !playlists[i].trackIds.contains(trackId) {
            playlists[i].trackIds.append(trackId)
            save()
        }
    }

    func removeTrack(_ trackId: UUID, from playlistId: UUID) {
        guard let i = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[i].trackIds.removeAll { $0 == trackId }
        save()
    }

    func rebuildSmartMix(allTracks: [Track], mood: Mood?) {
        guard let i = playlists.firstIndex(where: { $0.title == "Smart Mix" }) else { return }
        var pool = allTracks
        if let m = mood {
            let primary = allTracks.filter { $0.mood == m }.shuffled()
            let rest = allTracks.filter { $0.mood != m }.shuffled()
            pool = primary + rest
        } else {
            pool.shuffle()
        }
        playlists[i].trackIds = Array(pool.prefix(8)).map { $0.id }
        save()
    }

    private func save() {
        Persistence.save(playlists, key: StorageKeys.playlists)
    }
}
