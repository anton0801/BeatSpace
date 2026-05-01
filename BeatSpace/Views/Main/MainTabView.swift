import SwiftUI
import WebKit

struct MainTabView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.colorScheme) var scheme

    @State private var tab: Tab = .home
    @State private var showPlayer = false

    enum Tab: Int, CaseIterable {
        case home, discover, search, library, profile
        var title: String {
            switch self {
            case .home: return "Home"
            case .discover: return "Discover"
            case .search: return "Search"
            case .library: return "Library"
            case .profile: return "Profile"
            }
        }
        var symbol: String {
            switch self {
            case .home: return "house.fill"
            case .discover: return "sparkles"
            case .search: return "magnifyingglass"
            case .library: return "square.stack.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            Group {
                switch tab {
                case .home:     NavigationView { HomeView() }.navigationViewStyle(.stack)
                case .discover: NavigationView { DiscoverView() }.navigationViewStyle(.stack)
                case .search:   NavigationView { SearchView() }.navigationViewStyle(.stack)
                case .library:  NavigationView { LibraryView() }.navigationViewStyle(.stack)
                case .profile:  NavigationView { ProfileView() }.navigationViewStyle(.stack)
                }
            }
            .padding(.bottom, playerVM.currentTrack != nil ? 146 : 86)

            VStack(spacing: 8) {
                if playerVM.currentTrack != nil {
                    MiniPlayer { showPlayer = true }
                        .padding(.horizontal, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                CustomTabBar(tab: $tab)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playerVM.currentTrack?.id)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView()
        }
        .onAppear {
            playlistVM.seedIfNeeded(tracks: musicVM.tracks)
            statsVM.seedIfNeeded(tracks: musicVM.tracks)
            settingsVM.checkNotificationPermission()
        }
    }
}

// MARK: - Tab Bar
struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Binding var tab: MainTabView.Tab
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.rawValue) { t in
                Button {
                    Haptics.tap(settingsVM.hapticsOn)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        tab = t
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(t.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(tab == t ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if tab == t {
                                Capsule().fill(settingsVM.theme.gradient)
                                    .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 10)
                                    .matchedGeometryEffect(id: "tab", in: ns)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(scheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.stroke(scheme), lineWidth: 1)
        )
    }

    @Namespace var ns
}

// MARK: - Mini Player

struct MiniPlayer: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme
    var onTap: () -> Void

    var body: some View {
        if let t = playerVM.currentTrack {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(t.coverGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: t.mood.symbol)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(t.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Text(t.artist).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                }

                Spacer()

                Button { playerVM.previous() } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap(settingsVM.hapticsOn)
                    playerVM.togglePlay()
                } label: {
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(settingsVM.theme.gradient))
                        .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 8)
                }
                .buttonStyle(.plain)

                Button { playerVM.next() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(scheme == .dark ? Color.black.opacity(0.55) : Color.white.opacity(0.75))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.stroke(scheme), lineWidth: 1)
            )
            .overlay(
                // Progress bar
                VStack {
                    Spacer()
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(settingsVM.theme.gradient)
                            .frame(width: geo.size.width * CGFloat(playerVM.progress), height: 2)
                    }
                    .frame(height: 2)
                    .padding(.bottom, 2)
                    .padding(.horizontal, 10)
                }
            )
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
        }
    }
}
