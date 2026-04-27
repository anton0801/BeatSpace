import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showClearConfirm = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            if statsVM.activity.isEmpty {
                EmptyStateView(
                    symbol: "clock.arrow.circlepath",
                    title: "No activity yet",
                    message: "Your recent plays will appear here"
                )
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        // Grouped by day
                        ForEach(grouped, id: \.0) { dayLabel, items in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dayLabel)
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 18)
                                    .padding(.top, 6)

                                VStack(spacing: 6) {
                                    ForEach(items) { item in
                                        ActivityRow(item: item, theme: settingsVM.theme)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !statsVM.activity.isEmpty {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Clear Activity?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Haptics.notify(settingsVM.hapticsOn)
                withAnimation { statsVM.clearActivity() }
            }
        } message: {
            Text("This will remove all play history. This cannot be undone.")
        }
    }

    private var grouped: [(String, [ActivityItem])] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let dict = Dictionary(grouping: statsVM.activity) { item -> String in
            if cal.isDateInToday(item.playedAt) { return "TODAY" }
            if cal.isDateInYesterday(item.playedAt) { return "YESTERDAY" }
            return formatter.string(from: item.playedAt).uppercased()
        }
        // Order: keep TODAY first, YESTERDAY second, then by date desc
        let priority: (String) -> Int = { s in
            if s == "TODAY" { return 0 }
            if s == "YESTERDAY" { return 1 }
            return 2
        }
        return dict.sorted { (a, b) in
            let pa = priority(a.key), pb = priority(b.key)
            if pa != pb { return pa < pb }
            // For non-priority, compare via first item date desc
            return (a.value.first?.playedAt ?? .distantPast) > (b.value.first?.playedAt ?? .distantPast)
        }
    }
}

private struct ActivityRow: View {
    let item: ActivityItem
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(item.mood?.gradient ?? LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: item.mood?.symbol ?? "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.trackTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(item.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(durationString)
                    .font(.system(size: 11))
                    .foregroundColor(theme.primary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
    }

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: item.playedAt)
    }

    private var durationString: String {
        let m = item.durationListened / 60
        let s = item.durationListened % 60
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}
