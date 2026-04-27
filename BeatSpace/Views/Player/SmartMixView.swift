import SwiftUI

struct SmartMixView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var moodVM: MoodViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var refreshing = false

    private var smartMix: Playlist? {
        playlistVM.playlists.first { $0.isSystem && $0.title == "Smart Mix" }
    }

    private var tracks: [Track] {
        guard let mix = smartMix else { return [] }
        return mix.trackIds.compactMap { musicVM.track(by: $0) }
    }

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 18) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(settingsVM.theme.radial)
                            .frame(height: 220)
                            .shadow(color: settingsVM.theme.primary.opacity(0.4), radius: 20, y: 10)

                        VStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .bold))
                                Text("AI CURATED")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.5)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.2)))

                            Text("Smart Mix")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)

                            Text("Tuned to your \(moodVM.current.title) mood")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))

                            Text("\(tracks.count) tracks")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Actions
                    HStack(spacing: 12) {
                        NeonButton(title: "Play All", symbol: "play.fill", theme: settingsVM.theme) {
                            Haptics.tap(settingsVM.hapticsOn, style: .medium)
                            if let first = tracks.first {
                                playerVM.load(track: first, queue: tracks)
                                playerVM.play()
                            }
                        }
                        NeonButton(title: "Shuffle", symbol: "shuffle", theme: settingsVM.theme, filled: false) {
                            Haptics.tap(settingsVM.hapticsOn)
                            let shuffled = tracks.shuffled()
                            if let first = shuffled.first {
                                playerVM.load(track: first, queue: shuffled)
                                playerVM.shuffle = true
                                playerVM.play()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Refresh
                    Button {
                        Haptics.tap(settingsVM.hapticsOn, style: .medium)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { refreshing = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            playlistVM.rebuildSmartMix(allTracks: musicVM.tracks, mood: moodVM.current)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { refreshing = false }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .rotationEffect(.degrees(refreshing ? 360 : 0))
                                .animation(refreshing ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: refreshing)
                            Text(refreshing ? "Rebuilding..." : "Refresh Mix")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(settingsVM.theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.card(scheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(settingsVM.theme.primary.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    // Track list
                    VStack(spacing: 8) {
                        if tracks.isEmpty {
                            EmptyStateView(symbol: "sparkles", title: "No mix yet", message: "Tap refresh to build your Smart Mix")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            ForEach(tracks) { t in
                                TrackRow(track: t, queue: tracks)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Smart Mix")
        .navigationBarTitleDisplayMode(.inline)
    }
}
