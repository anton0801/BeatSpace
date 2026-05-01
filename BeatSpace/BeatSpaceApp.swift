import SwiftUI


struct BeatConstants {
    static let appReference = "6764061099"
    static let trackingDevKey = "7RaA7bJcTnQbCsahxSnnF9"
    static let realmSuite = "group.beatspace.realm"
    static let cookiePantry = "beatspace_pantry"
    static let backendURL = "https://beattspacce.com/config.php"
    static let logTag = "🎵 [BeatSpace]"
}

@main
struct BeatSpaceApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
            SplashView()
                .environmentObject(appState)
                .environmentObject(authVM)
                .environmentObject(musicVM)
                .environmentObject(playerVM)
                .environmentObject(moodVM)
                .environmentObject(settingsVM)
                .environmentObject(playlistVM)
                .environmentObject(statsVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
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
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appState.hasCompletedOnboarding)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: authVM.isAuthenticated)
        .preferredColorScheme(settingsVM.colorScheme)
        .accentColor(settingsVM.theme.primary)
    }
}
