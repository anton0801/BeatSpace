import SwiftUI

// MARK: - Shared Mode Scaffold

struct ModeView: View {
    let mood: Mood
    let title: String
    let tagline: String
    let iconSymbol: String

    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var moodVM: MoodViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    private var tracks: [Track] { musicVM.tracks(for: mood) }

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 20) {
                    hero
                    actions
                    stats
                    list
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(mood.gradient)
                .frame(height: 230)
                .shadow(color: mood.colors.first?.opacity(0.5) ?? .clear, radius: 20, y: 10)

            // Animated rings
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                }
            }

            VStack(spacing: 12) {
                Image(systemName: iconSymbol)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6)
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(tagline)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.horizontal, 16)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            NeonButton(title: "Start Session", symbol: "play.fill", theme: settingsVM.theme) {
                Haptics.tap(settingsVM.hapticsOn, style: .medium)
                moodVM.setMood(mood)
                if let first = tracks.first {
                    playerVM.load(track: first, queue: tracks)
                    playerVM.play()
                }
            }
            NeonButton(title: "Set Mood", symbol: mood.symbol, theme: settingsVM.theme, filled: false) {
                Haptics.tap(settingsVM.hapticsOn)
                moodVM.setMood(mood)
            }
        }
        .padding(.horizontal, 16)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            StatChip(icon: "music.note.list", value: "\(tracks.count)", label: "tracks", theme: settingsVM.theme)
            StatChip(icon: "speedometer", value: "\(mood.bpmRange.lowerBound)-\(mood.bpmRange.upperBound)", label: "BPM", theme: settingsVM.theme)
            StatChip(icon: "clock", value: formattedTotal, label: "total", theme: settingsVM.theme)
        }
        .padding(.horizontal, 16)
    }

    private var list: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tracks")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 18)

            if tracks.isEmpty {
                EmptyStateView(symbol: "music.note", title: "No tracks", message: "More music coming soon")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(tracks) { t in
                    TrackRow(track: t, queue: tracks)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private var formattedTotal: String {
        let total = tracks.reduce(0) { $0 + $1.durationSeconds }
        let m = total / 60
        if m >= 60 {
            let h = m / 60
            let rm = m % 60
            return "\(h)h \(rm)m"
        }
        return "\(m)m"
    }
}

private struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
    }
}

// MARK: - Wrappers

struct FocusModeView: View {
    var body: some View {
        ModeView(
            mood: .focus,
            title: "Focus Mode",
            tagline: "Deep concentration soundscapes to keep you in flow",
            iconSymbol: "brain.head.profile"
        )
    }
}

struct RelaxModeView: View {
    var body: some View {
        ModeView(
            mood: .chill,
            title: "Relax Mode",
            tagline: "Slow tempos and warm textures to unwind",
            iconSymbol: "leaf.fill"
        )
    }
}

struct EnergyModeView: View {
    var body: some View {
        ModeView(
            mood: .energy,
            title: "Energy Mode",
            tagline: "High BPM tracks to lift you up and move",
            iconSymbol: "bolt.fill"
        )
    }
}
