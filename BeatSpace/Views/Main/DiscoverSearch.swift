import SwiftUI

// MARK: - Mood Selector

struct MoodSelectorView: View {
    @EnvironmentObject var moodVM: MoodViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var selected: Mood

    init() {
        _selected = State(initialValue: .chill)
    }

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.card(scheme)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Select Mood")
                        .font(.system(size: 17, weight: .bold))
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(Mood.allCases) { mood in
                            MoodCardBig(
                                mood: mood,
                                selected: selected == mood
                            ) {
                                Haptics.tap(settingsVM.hapticsOn)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selected = mood
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                }

                NeonButton(title: "Apply Mood", symbol: "checkmark.circle.fill", theme: settingsVM.theme) {
                    Haptics.notify(settingsVM.hapticsOn)
                    moodVM.setMood(selected)
                    playlistVM.rebuildSmartMix(allTracks: musicVM.tracks, mood: selected)
                    let tracks = musicVM.tracks(for: selected)
                    if let first = tracks.first {
                        playerVM.load(track: first, queue: tracks)
                    }
                    dismiss()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .onAppear { selected = moodVM.current }
    }
}

struct MoodCardBig: View {
    let mood: Mood
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.22)).frame(width: 60, height: 60)
                    Image(systemName: mood.symbol)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(mood.title)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(mood.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                    Text("BPM \(mood.bpmRange.lowerBound)–\(mood.bpmRange.upperBound)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(mood.gradient)
                    .shadow(color: (mood.colors.first ?? .black).opacity(0.4), radius: selected ? 20 : 10, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(selected ? 0.6 : 0), lineWidth: 2)
            )
            .scaleEffect(selected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Discover

struct DiscoverView: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Discover")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    // Smart Mix banner
                    NavigationLink(destination: SmartMixView()) {
                        SmartMixBanner()
                            .padding(.horizontal, 18)
                    }
                    .buttonStyle(.plain)

                    // Categories
                    SectionHeader(title: "Categories")
                        .padding(.horizontal, 18)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(musicVM.discoverCategories) { cat in
                            NavigationLink(destination: CategoryView(category: cat)) {
                                CategoryCard(category: cat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)

                    // Mood playlists
                    SectionHeader(title: "By Mood")
                        .padding(.horizontal, 18)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(playlistVM.systemPlaylists().filter { $0.title != "Smart Mix" }) { p in
                            NavigationLink(destination: PlaylistDetailView(playlist: p)) {
                                DiscoverPlaylistCard(playlist: p)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct SmartMixBanner: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 64, height: 64)
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("SMART MIX")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                Text("AI-curated for you")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Adapts to your mood in real time")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(settingsVM.theme.gradient)
                .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 18, y: 8)
        )
    }
}

struct CategoryCard: View {
    let category: MusicViewModel.Category

    var body: some View {
        ZStack {
            LinearGradient(colors: category.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(16)
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: category.symbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(14)
        }
        .frame(height: 120)
        .shadow(color: (category.colors.first ?? .black).opacity(0.3), radius: 10, y: 4)
    }
}

struct DiscoverPlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let colors = playlist.mood?.colors ?? [.purple, .blue]
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(16)

            Image(systemName: playlist.mood?.symbol ?? "sparkles")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(playlist.trackIds.count) tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(14)
        }
        .frame(height: 130)
    }
}

struct CategoryView: View {
    let category: MusicViewModel.Category
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    var results: [Track] {
        if let g = category.genre { return musicVM.tracks(inGenre: g) }
        if let m = category.mood { return musicVM.tracks(for: m) }
        return []
    }

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        LinearGradient(colors: category.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 160)
                            .cornerRadius(20)
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(category.title)
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text("\(results.count) tracks")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: category.symbol)
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 18)

                    VStack(spacing: 10) {
                        ForEach(results) { t in
                            TrackRow(track: t, queue: results)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Search

struct SearchView: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var query: String = ""
    @FocusState private var focused: Bool

    var results: [Track] { musicVM.search(query) }

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            VStack(alignment: .leading, spacing: 14) {
                Text("Search")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search tracks, artists, genres…", text: $query)
                        .focused($focused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.card(scheme)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke(scheme), lineWidth: 1))
                .padding(.horizontal, 18)

                if query.isEmpty {
                    // Suggestions
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Popular Genres")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(["Lo-Fi", "Synthwave", "Ambient", "Pop", "Electronic", "Piano", "Jazz", "House", "Techno"], id: \.self) { g in
                                        Button {
                                            query = g
                                        } label: {
                                            PillTag(title: g, symbol: "music.note", theme: settingsVM.theme)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            SectionHeader(title: "Top Tracks")
                            ForEach(musicVM.tracks.prefix(6)) { t in
                                TrackRow(track: t, queue: Array(musicVM.tracks))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                    }
                } else {
                    ScrollView {
                        if results.isEmpty {
                            EmptyStateView(symbol: "magnifyingglass", title: "No results", message: "Try a different keyword, artist or genre.")
                        } else {
                            VStack(spacing: 10) {
                                ForEach(results) { t in
                                    TrackRow(track: t, queue: results)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 6)
                        }
                    }
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
