import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showClearConfirm = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            if statsVM.notifications.isEmpty {
                EmptyStateView(
                    symbol: "bell.slash",
                    title: "No notifications",
                    message: "We'll let you know when something interesting happens"
                )
            } else {
                List {
                    ForEach(statsVM.notifications) { n in
                        NotiRow(item: n, theme: settingsVM.theme)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptics.tap(settingsVM.hapticsOn)
                                if !n.isRead {
                                    statsVM.markRead(n.id)
                                }
                            }
                    }
                    .onDelete { offsets in
                        for idx in offsets {
                            let id = statsVM.notifications[idx].id
                            statsVM.deleteNotification(id)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackgroundCompat()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if statsVM.unreadCount > 0 {
                    Button("Read all") {
                        Haptics.tap(settingsVM.hapticsOn)
                        statsVM.markAllRead()
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
                if !statsVM.notifications.isEmpty {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .alert("Clear All?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Haptics.notify(settingsVM.hapticsOn)
                withAnimation { statsVM.clearAllNotifications() }
            }
        } message: {
            Text("All notifications will be removed.")
        }
    }
}

private struct NotiRow: View {
    let item: NotiItem
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(typeGradient)
                    .frame(width: 40, height: 40)
                Image(systemName: typeIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    if !item.isRead {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(item.body)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                Text(timeAgo)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(item.isRead ? Color.card(scheme) : theme.primary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(item.isRead ? Color.stroke(scheme) : theme.primary.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var typeIcon: String {
        switch item.type {
        case "new_track": return "music.note"
        case "mix":       return "sparkles"
        case "reminder":  return "bell.fill"
        default:          return "info.circle.fill"
        }
    }

    private var typeGradient: LinearGradient {
        switch item.type {
        case "new_track":
            return LinearGradient(colors: [Color(red: 0.30, green: 0.55, blue: 1.00), Color(red: 0.60, green: 0.25, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "mix":
            return LinearGradient(colors: [Color(red: 1.00, green: 0.35, blue: 0.55), Color(red: 0.60, green: 0.25, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "reminder":
            return LinearGradient(colors: [Color(red: 1.00, green: 0.70, blue: 0.20), Color(red: 1.00, green: 0.35, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return theme.gradient
        }
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(item.date)
        if interval < 60 { return "just now" }
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        }
        if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Helper to clear list background on iOS 16+

private extension View {
    @ViewBuilder
    func scrollContentBackgroundCompat() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self.onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
        }
    }
}
