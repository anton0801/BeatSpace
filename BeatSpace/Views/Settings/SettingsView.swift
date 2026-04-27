import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showResetConfirm = false
    @State private var showCacheClearedToast = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 18) {
                    appearanceSection
                    audioSection
                    notificationsSection
                    accountSection
                    aboutSection
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }

            if showCacheClearedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Cache cleared")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(settingsVM.theme.gradient))
                    .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 12)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Haptics.notify(settingsVM.hapticsOn)
                playerVM.pause()
                authVM.logout()
            }
        } message: {
            Text("You'll need to sign in again to access your account.")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Haptics.notify(settingsVM.hapticsOn, type: .warning)
                playerVM.pause()
                authVM.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all local data. This cannot be undone.")
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Haptics.notify(settingsVM.hapticsOn, type: .warning)
                settingsVM.resetAllData()
                playerVM.pause()
                authVM.logout()
            }
        } message: {
            Text("All settings, playlists, favorites, downloads, and history will be erased.")
        }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable notifications in iOS Settings to receive updates from Beat Space.")
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        SectionCard(title: "Appearance", scheme: scheme) {
            VStack(spacing: 14) {
                // Theme cards
                HStack(spacing: 10) {
                    ForEach(NeonTheme.allCases) { t in
                        ThemeCard(theme: t, selected: settingsVM.theme == t) {
                            Haptics.tap(settingsVM.hapticsOn)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                settingsVM.setTheme(t)
                            }
                        }
                    }
                }

                Divider().opacity(0.3)

                // Color scheme
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color Scheme")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        ForEach(SettingsViewModel.SchemeMode.allCases) { mode in
                            SchemeButton(
                                label: mode.rawValue.capitalized,
                                symbol: schemeSymbol(mode),
                                selected: settingsVM.schemeMode == mode,
                                theme: settingsVM.theme
                            ) {
                                Haptics.tap(settingsVM.hapticsOn)
                                settingsVM.setSchemeMode(mode)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func schemeSymbol(_ m: SettingsViewModel.SchemeMode) -> String {
        switch m {
        case .system: return "gear"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    // MARK: Audio

    private var audioSection: some View {
        SectionCard(title: "Audio", scheme: scheme) {
            VStack(spacing: 4) {
                NavigationLink(destination: EqualizerView()) {
                    SettingRow(symbol: "slider.horizontal.3", title: "Equalizer", value: equalizerLabel, theme: settingsVM.theme)
                }

                Divider().opacity(0.3)

                // Sound quality picker
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(settingsVM.theme.primary)
                        .frame(width: 28)
                    Text("Sound Quality")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Menu {
                        ForEach(SettingsViewModel.SoundQuality.allCases) { q in
                            Button {
                                Haptics.tap(settingsVM.hapticsOn)
                                settingsVM.soundQuality = q
                            } label: {
                                Label(q.title, systemImage: settingsVM.soundQuality == q ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(settingsVM.soundQuality.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(settingsVM.theme.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(settingsVM.theme.primary)
                        }
                    }
                }
                .padding(.vertical, 10)

                Divider().opacity(0.3)

                ToggleRow(symbol: "play.circle.fill", title: "Autoplay", isOn: $settingsVM.autoplay, theme: settingsVM.theme)
                Divider().opacity(0.3)
                ToggleRow(symbol: "arrow.left.and.right.circle.fill", title: "Crossfade", isOn: $settingsVM.crossfade, theme: settingsVM.theme)
                Divider().opacity(0.3)
                ToggleRow(symbol: "iphone.radiowaves.left.and.right", title: "Haptics", isOn: $settingsVM.hapticsOn, theme: settingsVM.theme)
            }
        }
        .padding(.horizontal, 16)
    }

    private var equalizerLabel: String {
        if settingsVM.equalizer == .flat { return "Flat" }
        for p in EqualizerSettings.Preset.allCases where EqualizerSettings.from(preset: p) == settingsVM.equalizer {
            return p.title
        }
        return "Custom"
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        SectionCard(title: "Notifications", scheme: scheme) {
            VStack(spacing: 4) {
                if !settingsVM.notifPermissionGranted {
                    Button {
                        Haptics.tap(settingsVM.hapticsOn)
                        settingsVM.requestNotificationPermission { granted in
                            if !granted {
                                showPermissionAlert = true
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(settingsVM.theme.gradient))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Notifications")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(scheme == .dark ? .white : .black)
                                Text("Permission required")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.3)
                }

                ToggleRow(symbol: "music.note.list", title: "New tracks", isOn: $settingsVM.notifNewTrack, theme: settingsVM.theme)
                Divider().opacity(0.3)
                ToggleRow(symbol: "sparkles", title: "Smart Mix updates", isOn: $settingsVM.notifMix, theme: settingsVM.theme)
                Divider().opacity(0.3)
                ToggleRow(symbol: "alarm.fill", title: "Daily reminder", isOn: $settingsVM.notifReminder, theme: settingsVM.theme)
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            settingsVM.checkNotificationPermission()
        }
    }

    // MARK: Account

    private var accountSection: some View {
        SectionCard(title: "Account", scheme: scheme) {
            VStack(spacing: 4) {
                Button {
                    Haptics.tap(settingsVM.hapticsOn)
                    settingsVM.clearCache()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showCacheClearedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { showCacheClearedToast = false }
                    }
                } label: {
                    SettingRow(symbol: "trash.circle.fill", title: "Clear Cache", value: nil, theme: settingsVM.theme)
                }
                .buttonStyle(.plain)

                Divider().opacity(0.3)

                Button {
                    showResetConfirm = true
                } label: {
                    SettingRow(symbol: "arrow.counterclockwise.circle.fill", title: "Reset All Data", value: nil, theme: settingsVM.theme)
                }
                .buttonStyle(.plain)

                Divider().opacity(0.3)

                Button {
                    showLogoutConfirm = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(settingsVM.theme.primary)
                            .frame(width: 28)
                        Text("Log Out")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(scheme == .dark ? .white : .black)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider().opacity(0.3)

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 28)
                        Text("Delete Account")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: About

    private var aboutSection: some View {
        SectionCard(title: "About", scheme: scheme) {
            VStack(spacing: 4) {
                InfoRow(label: "Version", value: "1.0.0", theme: settingsVM.theme)
                Divider().opacity(0.3)
                InfoRow(label: "Build", value: "100", theme: settingsVM.theme)
                Divider().opacity(0.3)
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(settingsVM.theme.primary)
                    Text("Beat Space")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("Made with ❤")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    let scheme: ColorScheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.card(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.stroke(scheme), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: NeonTheme
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.gradient)
                        .frame(height: 64)
                        .shadow(color: theme.primary.opacity(0.5), radius: 8, y: 4)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }
                Text(theme.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selected ? theme.primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scheme Button

private struct SchemeButton: View {
    let label: String
    let symbol: String
    let selected: Bool
    let theme: NeonTheme
    let action: () -> Void

    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(selected ? .white : (scheme == .dark ? .white : .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if selected { theme.gradient }
                    else { Color.card(scheme) }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.stroke(scheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setting Row

private struct SettingRow: View {
    let symbol: String
    let title: String
    let value: String?
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primary)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(scheme == .dark ? .white : .black)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Toggle Row

private struct ToggleRow: View {
    let symbol: String
    let title: String
    @Binding var isOn: Bool
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primary)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(scheme == .dark ? .white : .black)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: theme.primary))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let label: String
    let value: String
    let theme: NeonTheme

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
}
