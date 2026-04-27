import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 18) {
                    bigStat
                    statGrid
                    moodChart
                    topTracksCard
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bigStat: some View {
        VStack(spacing: 8) {
            Text("TOTAL LISTENED")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.85))
            Text(statsVM.totalListenedFormatted)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                Text("\(statsVM.streakDays) day streak")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.2)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(settingsVM.theme.radial)
                .shadow(color: settingsVM.theme.primary.opacity(0.4), radius: 20, y: 10)
        )
        .padding(.horizontal, 16)
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(icon: "music.note", value: "\(statsVM.tracksPlayed)", label: "Tracks Played", theme: settingsVM.theme)
            StatTile(icon: "heart.fill", value: "\(musicVM.favorites.count)", label: "Favorites", theme: settingsVM.theme)
            StatTile(icon: "arrow.down.circle.fill", value: "\(musicVM.downloads.count)", label: "Downloads", theme: settingsVM.theme)
            StatTile(
                icon: statsVM.topMood?.symbol ?? "sparkles",
                value: statsVM.topMood?.title ?? "—",
                label: "Top Mood",
                theme: settingsVM.theme
            )
        }
        .padding(.horizontal, 16)
    }

    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Breakdown")
                .font(.system(size: 16, weight: .bold))

            if statsVM.moodBreakdown.isEmpty {
                Text("No plays logged yet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            } else {
                let maxCount = max(1, statsVM.moodBreakdown.first?.1 ?? 1)
                VStack(spacing: 10) {
                    ForEach(statsVM.moodBreakdown, id: \.0) { item in
                        let mood = item.0
                        let count = item.1
                        HStack(spacing: 10) {
                            Image(systemName: mood.symbol)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(mood.gradient))

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(mood.title)
                                        .font(.system(size: 13, weight: .semibold))
                                    Spacer()
                                    Text("\(count)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.stroke(scheme)).frame(height: 8)
                                        Capsule()
                                            .fill(mood.gradient)
                                            .frame(
                                                width: geo.size.width * CGFloat(count) / CGFloat(maxCount),
                                                height: 8
                                            )
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private var topTracksCard: some View {
        let counts = Dictionary(grouping: statsVM.activity, by: { $0.trackTitle })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Most Played")
                .font(.system(size: 16, weight: .bold))

            if counts.isEmpty {
                Text("Play tracks to see them here")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(counts.enumerated()), id: \.element.key) { idx, pair in
                    HStack {
                        Text("\(idx + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(settingsVM.theme.primary)
                            .frame(width: 22, alignment: .leading)
                        Text(pair.key)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                        Text("\(pair.value)x")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    if idx < counts.count - 1 {
                        Divider().opacity(0.5)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

private struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.primary.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
    }
}
