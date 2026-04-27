import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var editingName = false
    @State private var draftName = ""

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    xpCard
                    quickStats
                    menuSection
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Edit Name", isPresented: $editingName) {
            TextField("Your name", text: $draftName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    authVM.updateName(trimmed)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(settingsVM.theme.gradient)
                    .frame(width: 104, height: 104)
                    .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 18)

                Text(initials)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(authVM.user?.name ?? "Guest")
                        .font(.system(size: 22, weight: .bold))
                    if !isGuestOrDemo {
                        Button {
                            draftName = authVM.user?.name ?? ""
                            editingName = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(settingsVM.theme.primary)
                                .padding(6)
                                .background(Circle().fill(settingsVM.theme.primary.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let u = authVM.user {
                    Text(u.isGuest ? "Guest mode" : (u.isDemo ? "Demo account" : u.email))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private var xpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(settingsVM.theme.primary)
                    Text("Level \(authVM.user?.level ?? 1)")
                        .font(.system(size: 16, weight: .bold))
                    PillTag(title: authVM.user?.levelTitle ?? "Listener", active: true, theme: settingsVM.theme)
                }
                Spacer()
                Text("\(authVM.user?.xp ?? 0) XP")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.stroke(scheme)).frame(height: 10)
                    Capsule()
                        .fill(settingsVM.theme.gradient)
                        .frame(width: geo.size.width * CGFloat(authVM.user?.progressToNext ?? 0), height: 10)
                        .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 10)

            HStack {
                Text("Next level")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                let toNext = 100 - ((authVM.user?.xp ?? 0) % 100)
                Text("\(toNext) XP to go")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(settingsVM.theme.primary)
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

    private var quickStats: some View {
        HStack(spacing: 10) {
            QuickStat(icon: "clock.fill", value: statsVM.totalListenedFormatted, label: "listened", theme: settingsVM.theme)
            QuickStat(icon: "music.note", value: "\(statsVM.tracksPlayed)", label: "plays", theme: settingsVM.theme)
            QuickStat(icon: "flame.fill", value: "\(statsVM.streakDays)", label: "streak", theme: settingsVM.theme)
        }
        .padding(.horizontal, 16)
    }

    private var menuSection: some View {
        VStack(spacing: 10) {
            NavigationLink(destination: StatsView()) {
                MenuRow(symbol: "chart.bar.fill", title: "Stats", subtitle: "Your listening analytics", theme: settingsVM.theme)
            }
            NavigationLink(destination: ActivityView()) {
                MenuRow(symbol: "list.bullet.rectangle.portrait", title: "Activity", subtitle: "Recent plays", theme: settingsVM.theme)
            }
            NavigationLink(destination: SocialView()) {
                MenuRow(symbol: "person.2.fill", title: "Social", subtitle: "Friends and sharing", theme: settingsVM.theme)
            }
            NavigationLink(destination: NotificationsView()) {
                MenuRow(
                    symbol: "bell.fill",
                    title: "Notifications",
                    subtitle: statsVM.unreadCount > 0 ? "\(statsVM.unreadCount) unread" : "All read",
                    theme: settingsVM.theme,
                    badge: statsVM.unreadCount
                )
            }
            NavigationLink(destination: SettingsView()) {
                MenuRow(symbol: "gearshape.fill", title: "Settings", subtitle: "Theme, audio, account", theme: settingsVM.theme)
            }
        }
        .padding(.horizontal, 16)
    }

    private var initials: String {
        guard let name = authVM.user?.name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        if let first = parts.first, let last = parts.dropFirst().first {
            return String(first.prefix(1) + last.prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var isGuestOrDemo: Bool {
        authVM.user?.isGuest == true || authVM.user?.isDemo == true
    }
}

private struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
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

private struct MenuRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let theme: NeonTheme
    var badge: Int = 0
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(theme.primary.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(scheme == .dark ? .white : .black)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(theme.accent))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
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
