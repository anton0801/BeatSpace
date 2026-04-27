import SwiftUI

@main
struct BeatSpaceApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var musicVM = MusicViewModel()
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var moodVM = MoodViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var playlistVM = PlaylistViewModel()
    @StateObject private var statsVM = StatsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authVM)
                .environmentObject(musicVM)
                .environmentObject(playerVM)
                .environmentObject(moodVM)
                .environmentObject(settingsVM)
                .environmentObject(playlistVM)
                .environmentObject(statsVM)
                .preferredColorScheme(settingsVM.colorScheme)
                .accentColor(settingsVM.theme.primary)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            if appState.showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
                    .transition(.opacity)
            } else if !authVM.isAuthenticated {
                WelcomeView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appState.showSplash)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appState.hasCompletedOnboarding)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: authVM.isAuthenticated)
    }
}
