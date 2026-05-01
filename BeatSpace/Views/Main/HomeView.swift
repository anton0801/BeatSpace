import SwiftUI
import WebKit

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var moodVM: MoodViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var showMoodSelector = false
    @State private var showNotifications = false

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                    // Current mood card
                    currentMoodCard
                        .padding(.horizontal, 18)

                    // Quick actions
                    quickActions
                        .padding(.horizontal, 18)

                    // Recommended
                    recommendedSection

                    // System playlists
                    playlistsSection

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showMoodSelector) {
            MoodSelectorView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(authVM.user?.name ?? "Listener")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
            }
            Spacer()
            Button {
                Haptics.tap(settingsVM.hapticsOn)
                showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.card(scheme)))
                        .overlay(Circle().stroke(Color.stroke(scheme), lineWidth: 1))
                    if statsVM.unreadCount > 0 {
                        Circle()
                            .fill(settingsVM.theme.primary)
                            .frame(width: 10, height: 10)
                            .offset(x: -6, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "GOOD MORNING"
        case 12..<18: return "GOOD AFTERNOON"
        default: return "GOOD EVENING"
        }
    }

    private var currentMoodCard: some View {
        Button {
            Haptics.tap(settingsVM.hapticsOn)
            showMoodSelector = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(moodVM.current.gradient)
                    .shadow(color: (moodVM.current.colors.first ?? .black).opacity(0.45), radius: 22, y: 10)

                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 64, height: 64)
                        Image(systemName: moodVM.current.symbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CURRENT MOOD")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                        Text(moodVM.current.title)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(moodVM.current.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(18)
            }
            .frame(height: 120)
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: FocusModeView()) {
                QuickActionCard(title: "Focus", symbol: "brain.head.profile", colors: Mood.focus.colors)
            }
            NavigationLink(destination: RelaxModeView()) {
                QuickActionCard(title: "Relax", symbol: "leaf.fill", colors: Mood.chill.colors)
            }
            NavigationLink(destination: EnergyModeView()) {
                QuickActionCard(title: "Energy", symbol: "bolt.fill", colors: Mood.energy.colors)
            }
        }
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recommended for You")
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(musicVM.recommended(for: moodVM.current, limit: 8), id: \.id) { t in
                        TrackCard(track: t)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Vibes")
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(playlistVM.systemPlaylists()) { p in
                        NavigationLink(destination: PlaylistDetailView(playlist: p)) {
                            PlaylistCard(playlist: p)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = BeatConstants.cookiePantry
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(BeatConstants.logTag) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let symbol: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.22)).frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: (colors.first ?? .black).opacity(0.4), radius: 14, y: 6)
        )
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(BeatConstants.logTag) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct TrackCard: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    let track: Track

    var body: some View {
        Button {
            playerVM.load(track: track, queue: musicVM.tracks(for: track.mood))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(track.coverGradient)
                        .frame(width: 148, height: 148)
                    Image(systemName: track.mood.symbol)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 32, weight: .bold))
                        .padding(14)
                }
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 148)
        }
        .buttonStyle(.plain)
    }
}
extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}


struct PlaylistCard: View {
    let playlist: Playlist
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var gradient: LinearGradient {
        if let m = playlist.mood { return m.gradient }
        return settingsVM.theme.gradient
    }

    var symbol: String {
        if let m = playlist.mood { return m.symbol }
        return "sparkles"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gradient)
                    .frame(width: 160, height: 160)
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            Text(playlist.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text("\(playlist.trackIds.count) tracks")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}
extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
