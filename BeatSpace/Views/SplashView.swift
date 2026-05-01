import SwiftUI
import Combine
import AppsFlyerLib
import Network

struct SplashView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme
    
    // Animation drivers
    @State private var t: Double = 0
    @State private var vinylAppeared = false
    @State private var vinylScale: CGFloat = 0.2
    @State private var vinylRotation: Double = 0
    @State private var ringPulse: CGFloat = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var eqAwake: Bool = false
    @State private var beatFlash: Double = 0
    @State private var orbitProgress: Double = 0
    
    @StateObject private var viewModel = BeatSpaceViewModel()
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    // Pulsing rings emitted from center
    @State private var ripples: [Ripple] = []
    @State private var orbitingNotes: [OrbitNote] = []
    
    private let frameTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                
                ZStack {
                    // Deep gradient background — darker than AppBackground for splash drama
                    LinearGradient(
                        colors: [
                            Color.black,
                            settingsVM.theme.secondary.opacity(0.5),
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    Image("splash_lcl")
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 8)
                        .opacity(0.6)
                    
                    NavigationLink(
                        destination: BeatSpaceWebView().navigationBarHidden(true),
                        isActive: $viewModel.navigateToWeb
                    ) { EmptyView() }
                    
                    NavigationLink(
                        destination: RootView().navigationBarBackButtonHidden(true),
                        isActive: $viewModel.navigateToMain
                    ) { EmptyView() }
                    
                    // Soft ambient glow following the vinyl
                    Circle()
                        .fill(settingsVM.theme.primary.opacity(0.45))
                        .frame(width: 380, height: 380)
                        .blur(radius: 90)
                        .position(center)
                        .opacity(vinylAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 1.2), value: vinylAppeared)
                    
                    Circle()
                        .fill(settingsVM.theme.accent.opacity(0.30))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .position(x: center.x + 50, y: center.y + 80)
                        .opacity(vinylAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 1.4).delay(0.2), value: vinylAppeared)
                    
                    // Pulsing ripples from center (like a kick drum)
                    ForEach(ripples) { r in
                        Circle()
                            .stroke(
                                settingsVM.theme.gradient,
                                style: StrokeStyle(lineWidth: max(0.5, 4 - r.age * 4), lineCap: .round)
                            )
                            .frame(width: r.radius * 2, height: r.radius * 2)
                            .position(center)
                            .opacity(max(0, 0.7 - r.age))
                            .blur(radius: r.age * 2)
                    }
                    
                    // Orbiting music notes (drawn around the vinyl)
                    ForEach(orbitingNotes) { note in
                        let angle = note.startAngle + orbitProgress * note.speed
                        let r = note.radius - orbitProgress * note.inwardPull * 60
                        let x = center.x + CGFloat(cos(angle)) * max(40, r)
                        let y = center.y + CGFloat(sin(angle)) * max(40, r)
                        Image(systemName: note.symbol)
                            .font(.system(size: note.size, weight: .bold))
                            .foregroundColor(.white.opacity(note.opacity))
                            .shadow(color: settingsVM.theme.primary.opacity(0.8), radius: 6)
                            .position(x: x, y: y)
                            .opacity(vinylAppeared ? 1 : 0)
                    }
                    
                    // Vinyl record at center
                    vinyl
                        .frame(width: 220, height: 220)
                        .scaleEffect(vinylScale)
                        .rotationEffect(.degrees(vinylRotation))
                        .position(center)
                        .opacity(vinylAppeared ? 1 : 0)
                    
                    // Title block (positioned below vinyl)
                    VStack(spacing: 8) {
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        Text("BEAT SPACE")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(settingsVM.theme.gradient)
                            .shadow(color: settingsVM.theme.primary.opacity(0.7), radius: 14)
                            .offset(y: titleOffset)
                            .opacity(titleOpacity)
                        
                        Text("Feel your rhythm")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(subtitleOpacity)
                        
                        Spacer()
                        
                        // EQ wave at bottom
                        eqWave(width: geo.size.width)
                            .frame(height: 70)
                            .padding(.bottom, 70)
                            .opacity(eqAwake ? 1 : 0)
                    }
                }
                .onAppear {
                    generateNotes(center: center)
                    animateSequence()
                }
                .onReceive(frameTimer) { _ in
                    t += 0.02
                    advanceRipples()
                    orbitProgress += 0.012
                }
            }
            .ignoresSafeArea()
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                BeatSpaceApprovalView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
            .onAppear {
                setupStreams()
                setupNetworkMonitoring()
                viewModel.boot()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Vinyl record
    
    private var vinyl: some View {
        ZStack {
            // Outer disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.08),
                            Color(white: 0.02)
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 110
                    )
                )
                .shadow(color: settingsVM.theme.primary.opacity(0.6), radius: 30)
            
            // Concentric grooves with subtle neon tint
            ForEach(0..<14, id: \.self) { i in
                Circle()
                    .stroke(
                        Color.white.opacity(i % 3 == 0 ? 0.08 : 0.04),
                        lineWidth: 0.5
                    )
                    .frame(width: 200 - CGFloat(i) * 12, height: 200 - CGFloat(i) * 12)
            }
            
            // Highlight sweep on the disc — gives it 3D shine
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            settingsVM.theme.primary.opacity(0.0),
                            settingsVM.theme.primary.opacity(0.35),
                            settingsVM.theme.accent.opacity(0.5),
                            settingsVM.theme.primary.opacity(0.35),
                            settingsVM.theme.primary.opacity(0.0)
                        ],
                        center: .center
                    )
                )
                .frame(width: 210, height: 210)
                .blendMode(.screen)
                .opacity(0.9)
            
            // Center label disc
            Circle()
                .fill(settingsVM.theme.gradient)
                .frame(width: 78, height: 78)
                .shadow(color: settingsVM.theme.primary.opacity(0.7), radius: 14)
            
            // Subtle ring around label
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                .frame(width: 78, height: 78)
            
            // Spindle hole
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
            
            // Pulsing beat ring around the label (sized by beatFlash)
            Circle()
                .stroke(settingsVM.theme.accent, lineWidth: 2)
                .frame(width: 78 + CGFloat(beatFlash) * 60, height: 78 + CGFloat(beatFlash) * 60)
                .opacity(1 - beatFlash)
        }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }
    // MARK: - EQ Wave
    
    private func eqWave(width: CGFloat) -> some View {
        let bars = 60
        let spacing: CGFloat = 3
        let barWidth = (width - CGFloat(bars - 1) * spacing - 32) / CGFloat(bars)
        
        return HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<bars, id: \.self) { i in
                Capsule()
                    .fill(settingsVM.theme.gradient)
                    .frame(width: max(2, barWidth), height: barHeight(for: i))
                    .shadow(color: settingsVM.theme.primary.opacity(0.6), radius: 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func barHeight(for i: Int) -> CGFloat {
        guard eqAwake else { return 4 }
        // Two travelling waves layered for richness
        let phase = t * 2.2
        let pos = Double(i) * 0.18
        let wave1 = sin(phase + pos)
        let wave2 = sin(phase * 0.7 - pos * 1.4) * 0.6
        let combined = abs(wave1 + wave2) * 0.5 + 0.1
        // Beat punch — every ripple emit, all bars get a small kick
        let beatBoost = beatFlash * 0.3
        return CGFloat(8 + (combined + beatBoost) * 50)
    }
    
    // MARK: - Ripples
    
    private struct Ripple: Identifiable {
        let id = UUID()
        var radius: CGFloat
        var age: Double // 0..1
    }
    
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func advanceRipples() {
        for i in ripples.indices {
            ripples[i].radius += 4.2
            ripples[i].age += 0.018
        }
        ripples.removeAll { $0.age >= 1 }
    }
    
    private func emitRipple() {
        ripples.append(Ripple(radius: 50, age: 0))
        // Trigger beat flash
        withAnimation(.easeOut(duration: 0.5)) { beatFlash = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 0)) { beatFlash = 0 }
        }
    }
    
    // MARK: - Orbiting notes
    
    private struct OrbitNote: Identifiable {
        let id = UUID()
        let symbol: String
        let radius: CGFloat
        let startAngle: Double
        let speed: Double
        let size: CGFloat
        let opacity: Double
        let inwardPull: Double
    }
    
    private func generateNotes(center: CGPoint) {
        let symbols = ["music.note", "music.note", "music.quarternote.3", "music.note", "music.note"]
        orbitingNotes = (0..<10).map { i in
            OrbitNote(
                symbol: symbols.randomElement()!,
                radius: CGFloat.random(in: 130...210),
                startAngle: Double(i) * (2 * .pi / 10) + Double.random(in: -0.3...0.3),
                speed: Double.random(in: 0.6...1.4) * (i % 2 == 0 ? 1 : -1),
                size: CGFloat.random(in: 12...22),
                opacity: Double.random(in: 0.4...0.8),
                inwardPull: Double.random(in: 0.0...0.5)
            )
        }
    }
    
    // MARK: - Animation Sequence
    
    private func animateSequence() {
        // 1. Vinyl pops in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            vinylAppeared = true
            vinylScale = 1.0
        }
        
        // 2. Vinyl starts spinning slowly, then accelerates
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false).delay(0.3)) {
            vinylRotation = 360
        }
        
        // 3. First beat ripple after vinyl appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { emitRipple() }
        // Subsequent beats — ~600ms apart, like a 100bpm kick
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) { emitRipple() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) { emitRipple() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) { emitRipple() }
        
        // 4. EQ wave wakes up
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            eqAwake = true
        }
        
        // 5. Title appears with delay
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(1.0)) {
            titleOpacity = 1
            titleOffset = 0
        }
        
        // 6. Subtitle
        withAnimation(.easeOut(duration: 0.6).delay(1.4)) {
            subtitleOpacity = 1
        }
    }
}


