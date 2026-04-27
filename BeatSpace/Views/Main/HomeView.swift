import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var moodVM: MoodViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showMoodSelector = false
    @State private var showNotifications = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                    // Current mood card
                    currentMoodCard
                        .padding(.horizontal, 18)

                    // Quick actions
                    quickActions
                        .padding(.horizontal, 18)

                    // Recommended
                    recommendedSection

                    // System playlists
                    playlistsSection

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showMoodSelector) {
            MoodSelectorView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(authVM.user?.name ?? "Listener")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
            }
            Spacer()
            Button {
                Haptics.tap(settingsVM.hapticsOn)
                showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.card(scheme)))
                        .overlay(Circle().stroke(Color.stroke(scheme), lineWidth: 1))
                    if statsVM.unreadCount > 0 {
                        Circle()
                            .fill(settingsVM.theme.primary)
                            .frame(width: 10, height: 10)
                            .offset(x: -6, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "GOOD MORNING"
        case 12..<18: return "GOOD AFTERNOON"
        default: return "GOOD EVENING"
        }
    }

    private var currentMoodCard: some View {
        Button {
            Haptics.tap(settingsVM.hapticsOn)
            showMoodSelector = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(moodVM.current.gradient)
                    .shadow(color: (moodVM.current.colors.first ?? .black).opacity(0.45), radius: 22, y: 10)

                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 64, height: 64)
                        Image(systemName: moodVM.current.symbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CURRENT MOOD")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                        Text(moodVM.current.title)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(moodVM.current.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(18)
            }
            .frame(height: 120)
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: FocusModeView()) {
                QuickActionCard(title: "Focus", symbol: "brain.head.profile", colors: Mood.focus.colors)
            }
            NavigationLink(destination: RelaxModeView()) {
                QuickActionCard(title: "Relax", symbol: "leaf.fill", colors: Mood.chill.colors)
            }
            NavigationLink(destination: EnergyModeView()) {
                QuickActionCard(title: "Energy", symbol: "bolt.fill", colors: Mood.energy.colors)
            }
        }
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recommended for You")
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(musicVM.recommended(for: moodVM.current, limit: 8), id: \.id) { t in
                        TrackCard(track: t)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Vibes")
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(playlistVM.systemPlaylists()) { p in
                        NavigationLink(destination: PlaylistDetailView(playlist: p)) {
                            PlaylistCard(playlist: p)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let symbol: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.22)).frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: (colors.first ?? .black).opacity(0.4), radius: 14, y: 6)
        )
    }
}

struct TrackCard: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    let track: Track

    var body: some View {
        Button {
            playerVM.load(track: track, queue: musicVM.tracks(for: track.mood))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(track.coverGradient)
                        .frame(width: 148, height: 148)
                    Image(systemName: track.mood.symbol)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 32, weight: .bold))
                        .padding(14)
                }
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 148)
        }
        .buttonStyle(.plain)
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var gradient: LinearGradient {
        if let m = playlist.mood { return m.gradient }
        return settingsVM.theme.gradient
    }

    var symbol: String {
        if let m = playlist.mood { return m.symbol }
        return "sparkles"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gradient)
                    .frame(width: 160, height: 160)
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            Text(playlist.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text("\(playlist.trackIds.count) tracks")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}
