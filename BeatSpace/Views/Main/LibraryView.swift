import SwiftUI

// MARK: - Library

struct LibraryView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var tab: Int = 0
    @State private var showCreate = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            VStack(spacing: 14) {
                HStack {
                    Text("Library")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Spacer()
                    if tab == 0 {
                        Button {
                            Haptics.tap(settingsVM.hapticsOn)
                            showCreate = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(settingsVM.theme.gradient))
                                .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                // Segmented
                HStack(spacing: 6) {
                    SegButton(title: "Playlists", idx: 0, bind: $tab, theme: settingsVM.theme)
                    SegButton(title: "Favorites", idx: 1, bind: $tab, theme: settingsVM.theme)
                    SegButton(title: "Downloads", idx: 2, bind: $tab, theme: settingsVM.theme)
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.card(scheme)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke(scheme), lineWidth: 1))
                .padding(.horizontal, 18)

                Group {
                    switch tab {
                    case 0: PlaylistsTab()
                    case 1: FavoritesView()
                    default: DownloadsView()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreate) {
            CreatePlaylistView()
        }
    }
}

struct SegButton: View {
    let title: String
    let idx: Int
    @Binding var bind: Int
    let theme: NeonTheme

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { bind = idx }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(bind == idx ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if bind == idx {
                            RoundedRectangle(cornerRadius: 10).fill(theme.gradient)
                                .shadow(color: theme.primary.opacity(0.4), radius: 8)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Playlists Tab

struct BeatSpaceWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: PantryKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: PantryKey.endpoint) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: PantryKey.pushURL) }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: PantryKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: PantryKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct PlaylistsTab: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !playlistVM.userPlaylists().isEmpty {
                    SectionHeader(title: "Your Playlists").padding(.horizontal, 18)
                    ForEach(playlistVM.userPlaylists()) { p in
                        NavigationLink(destination: PlaylistDetailView(playlist: p)) {
                            PlaylistRow(playlist: p)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                }

                SectionHeader(title: "System").padding(.horizontal, 18).padding(.top, 8)
                ForEach(playlistVM.systemPlaylists()) { p in
                    NavigationLink(destination: PlaylistDetailView(playlist: p)) {
                        PlaylistRow(playlist: p)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                }

                if playlistVM.userPlaylists().isEmpty {
                    EmptyStateView(
                        symbol: "music.note.list",
                        title: "Create your first playlist",
                        message: "Tap the + button to build your own mix."
                    )
                    .padding(.top, 10)
                }

                Spacer(minLength: 16)
            }
            .padding(.top, 8)
        }
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    @Environment(\.colorScheme) var scheme
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(playlist.mood?.gradient ?? settingsVM.theme.gradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: playlist.mood?.symbol ?? "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title).font(.system(size: 15, weight: .semibold))
                Text("\(playlist.trackIds.count) tracks · \(playlist.isSystem ? "System" : "User")")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.card(scheme)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke(scheme), lineWidth: 1))
    }
}

// MARK: - Create Playlist

struct CreatePlaylistView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var selectedTrackIds: Set<UUID> = []
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.card(scheme)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("New Playlist").font(.system(size: 17, weight: .bold))
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                    // Cover preview
                    ZStack {
                        Circle()
                            .fill(settingsVM.theme.gradient)
                            .frame(width: 130, height: 130)
                            .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 20)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 12) {
                        NeonTextField(placeholder: "Playlist name", text: $title, symbol: "textformat", theme: settingsVM.theme)
                        NeonTextField(placeholder: "Description (optional)", text: $desc, symbol: "text.alignleft", theme: settingsVM.theme)
                    }
                    .padding(.horizontal, 18)

                    if let e = errorMsg {
                        Text(e).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 18)
                    }

                    HStack {
                        Text("Add tracks (\(selectedTrackIds.count))").font(.system(size: 15, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    VStack(spacing: 8) {
                        ForEach(musicVM.tracks) { t in
                            Button {
                                if selectedTrackIds.contains(t.id) {
                                    selectedTrackIds.remove(t.id)
                                } else {
                                    selectedTrackIds.insert(t.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 10).fill(t.coverGradient).frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                                        Text(t.artist).font(.system(size: 11)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedTrackIds.contains(t.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedTrackIds.contains(t.id) ? settingsVM.theme.primary : .secondary)
                                        .font(.system(size: 22))
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.card(scheme)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stroke(scheme), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)

                    NeonButton(title: "Create Playlist", symbol: "plus.circle.fill", theme: settingsVM.theme) {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else {
                            errorMsg = "Please enter a name"
                            return
                        }
                        _ = playlistVM.create(title: trimmed, desc: desc, trackIds: Array(selectedTrackIds))
                        Haptics.notify(settingsVM.hapticsOn)
                        dismiss()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                    Spacer(minLength: 30)
                }
            }
        }
    }
}

// MARK: - Playlist Detail

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme
    @Environment(\.dismiss) var dismiss

    @State private var confirmDelete = false

    var tracks: [Track] { playlist.trackIds.compactMap(musicVM.track(by:)) }

    var gradient: LinearGradient {
        playlist.mood?.gradient ?? settingsVM.theme.gradient
    }

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(gradient)
                                .frame(width: 180, height: 180)
                                .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 25)
                            Image(systemName: playlist.mood?.symbol ?? "sparkles")
                                .font(.system(size: 70, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        Text(playlist.title)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                        if !playlist.desc.isEmpty {
                            Text(playlist.desc)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        Text("\(tracks.count) tracks").font(.system(size: 12)).foregroundColor(.secondary)
                    }
                    .padding(.top, 10)

                    HStack(spacing: 10) {
                        NeonButton(title: "Play", symbol: "play.fill", theme: settingsVM.theme) {
                            if let first = tracks.first {
                                playerVM.load(track: first, queue: tracks)
                            }
                        }
                        Button {
                            playerVM.shuffle = true
                            let shuffled = tracks.shuffled()
                            if let first = shuffled.first { playerVM.load(track: first, queue: shuffled) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "shuffle")
                                Text("Shuffle").fontWeight(.bold)
                            }
                            .font(.system(size: 15))
                            .foregroundColor(settingsVM.theme.primary)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 16).stroke(settingsVM.theme.primary, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)

                    VStack(spacing: 10) {
                        if tracks.isEmpty {
                            EmptyStateView(symbol: "music.note", title: "Empty playlist", message: "Add tracks from the library.")
                        } else {
                            ForEach(tracks) { t in
                                HStack {
                                    TrackRow(track: t, queue: tracks)
                                    if !playlist.isSystem {
                                        Button {
                                            playlistVM.removeTrack(t.id, from: playlist.id)
                                        } label: {
                                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    if !playlist.isSystem {
                        Button {
                            confirmDelete = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Delete Playlist").fontWeight(.bold)
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.12)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this playlist?", isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                playlistVM.delete(playlist.id)
                dismiss()
            }
        } message: {
            Text("This action can't be undone.")
        }
    }
}

// MARK: - Favorites

struct FavoritesView: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if musicVM.favoriteTracks.isEmpty {
                    EmptyStateView(symbol: "heart", title: "No favorites yet", message: "Tap the heart on any track to save it here.")
                } else {
                    ForEach(musicVM.favoriteTracks) { t in
                        TrackRow(track: t, queue: musicVM.favoriteTracks)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
        }
    }
}

// MARK: - Downloads

struct DownloadsView: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if musicVM.downloadedTracks.isEmpty {
                    EmptyStateView(symbol: "arrow.down.circle", title: "No downloads", message: "Download tracks to listen offline.")

                    // Quick suggestions
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Suggested")
                        ForEach(musicVM.tracks.prefix(5)) { t in
                            TrackRow(track: t, queue: Array(musicVM.tracks), showDownload: true)
                        }
                    }
                    .padding(.top, 12)
                } else {
                    ForEach(musicVM.downloadedTracks) { t in
                        TrackRow(track: t, queue: musicVM.downloadedTracks, showDownload: true)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
        }
    }
}
