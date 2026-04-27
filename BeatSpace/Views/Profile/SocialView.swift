import SwiftUI

struct SocialView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    private let mockFriends: [(name: String, mood: Mood, listening: String)] = [
        ("Alex Rivers", .focus, "Deep Currents"),
        ("Maya Chen", .chill, "Soft Tide"),
        ("Sam Voss", .energy, "Volt Surge"),
        ("Jordan Fox", .happy, "Sunlit Avenue")
    ]

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 18) {
                    hero
                    friendsList
                    inviteCard
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(settingsVM.theme.gradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 20)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("Friends Soon")
                .font(.system(size: 22, weight: .bold))
            Text("Share what you're listening to and see your friends' moods in real time")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            PillTag(title: "COMING SOON", active: true, theme: settingsVM.theme)
                .padding(.top, 4)
        }
        .padding(.top, 12)
    }

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Preview")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("Mock data")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)

            VStack(spacing: 8) {
                ForEach(mockFriends, id: \.name) { f in
                    FriendRow(name: f.name, mood: f.mood, listening: f.listening, theme: settingsVM.theme)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private var inviteCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(settingsVM.theme.primary)
            Text("Want early access?")
                .font(.system(size: 16, weight: .bold))
            Text("Join the waitlist to be the first to use Beat Space Social.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            NeonButton(title: "Notify Me", symbol: "bell.fill", theme: settingsVM.theme) {
                Haptics.notify(settingsVM.hapticsOn)
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.card(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.stroke(scheme), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

private struct FriendRow: View {
    let name: String
    let mood: Mood
    let listening: String
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    private var initials: String {
        name.split(separator: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined()
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mood.gradient)
                    .frame(width: 46, height: 46)
                Text(initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Circle()
                    .fill(theme.primary)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.card(scheme), lineWidth: 2))
                    .offset(x: 16, y: 16)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 4) {
                    Image(systemName: mood.symbol)
                        .font(.system(size: 10))
                    Text("Listening to \(listening)")
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
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
        .opacity(0.85)
    }
}
