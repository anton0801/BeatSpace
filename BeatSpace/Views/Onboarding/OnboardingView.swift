import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    @State private var page: Int = 0
    @State private var dragOffset: CGFloat = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            kind: .waves,
            title: "Feel Your Rhythm",
            subtitle: "Immerse in neon soundscapes that move with your pulse. Your next favorite vibe is one swipe away.",
            symbol: "waveform.path.ecg"
        ),
        OnboardingPage(
            kind: .moods,
            title: "Control Your Mood",
            subtitle: "Pick how you want to feel — Happy, Chill, Focus, Energy, Sad — and watch the music shift instantly.",
            symbol: "face.smiling.inverse"
        ),
        OnboardingPage(
            kind: .ai,
            title: "Music That Adapts",
            subtitle: "Our Smart Mix learns your taste and curates sessions that fit exactly where your head is right now.",
            symbol: "sparkles"
        )
    ]

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        Haptics.tap(settingsVM.hapticsOn)
                        appState.completeOnboarding()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 18)
                    .padding(.top, 8)
                }

                // Page content
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(pages.indices, id: \.self) { i in
                            OnboardingPageView(page: pages[i], index: i, currentIndex: page)
                                .frame(width: geo.size.width)
                        }
                    }
                    .offset(x: -CGFloat(page) * geo.size.width + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 60
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if value.translation.width < -threshold && page < pages.count - 1 {
                                        page += 1
                                        Haptics.tap(settingsVM.hapticsOn)
                                    } else if value.translation.width > threshold && page > 0 {
                                        page -= 1
                                        Haptics.tap(settingsVM.hapticsOn)
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
                }

                // Dots
                HStack(spacing: 10) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AnyShapeStyle(settingsVM.theme.gradient) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                            .frame(width: i == page ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.bottom, 20)

                // Buttons
                HStack(spacing: 14) {
                    if page > 0 {
                        Button {
                            Haptics.tap(settingsVM.hapticsOn)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { page -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(settingsVM.theme.primary)
                                .frame(width: 54, height: 54)
                                .background(Circle().fill(Color.card(scheme)))
                                .overlay(Circle().stroke(settingsVM.theme.primary, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }

                    NeonButton(
                        title: page == pages.count - 1 ? "Get Started" : "Next",
                        symbol: page == pages.count - 1 ? "arrow.right.circle.fill" : "arrow.right",
                        theme: settingsVM.theme
                    ) {
                        Haptics.tap(settingsVM.hapticsOn)
                        if page < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { page += 1 }
                        } else {
                            appState.completeOnboarding()
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    enum Kind { case waves, moods, ai }
    let kind: Kind
    let title: String
    let subtitle: String
    let symbol: String
}

struct OnboardingPageView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let page: OnboardingPage
    let index: Int
    let currentIndex: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Hero illustration
            ZStack {
                switch page.kind {
                case .waves: WavesHero(theme: settingsVM.theme)
                case .moods: MoodsHero(theme: settingsVM.theme)
                case .ai:    AIHero(theme: settingsVM.theme)
                }
            }
            .frame(height: 260)
            .scaleEffect(currentIndex == index ? 1.0 : 0.85)
            .opacity(currentIndex == index ? 1.0 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentIndex)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
    }
}

// MARK: - Hero illustrations

struct WavesHero: View {
    let theme: NeonTheme
    @State private var phase: Double = 0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.2))
                .frame(width: 240, height: 240)
                .blur(radius: 30)

            ForEach(0..<3) { i in
                WaveShape(phase: phase + Double(i) * 0.8, amplitude: 18 - CGFloat(i) * 4)
                    .stroke(theme.primary.opacity(0.8 - Double(i) * 0.2), lineWidth: 3 - CGFloat(i) * 0.5)
                    .frame(height: 120)
            }
        }
        .onReceive(timer) { _ in
            phase += 0.1
        }
    }
}

struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midY = rect.midY
        p.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = Double(x / rect.width)
            let y = midY + sin(relativeX * .pi * 4 + phase) * amplitude
            p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }
}

struct MoodsHero: View {
    let theme: NeonTheme
    @State private var rotation: Double = 0

    private let moods = Mood.allCases

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.15))
                .frame(width: 220, height: 220)
                .blur(radius: 20)

            ForEach(moods.indices, id: \.self) { i in
                let angle = Double(i) / Double(moods.count) * 360 + rotation
                let radius: CGFloat = 100
                let x = cos(angle * .pi / 180) * radius
                let y = sin(angle * .pi / 180) * radius
                Circle()
                    .fill(moods[i].gradient)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: moods[i].symbol)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                    )
                    .shadow(color: moods[i].colors.first ?? .black, radius: 12)
                    .offset(x: x, y: y)
            }

            Circle()
                .fill(theme.gradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 30, weight: .bold))
                )
                .shadow(color: theme.primary.opacity(0.7), radius: 20)
        }
        .onAppear {
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct AIHero: View {
    let theme: NeonTheme
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(theme.primary.opacity(0.4 - Double(i) * 0.1), lineWidth: 2)
                    .frame(width: 100 + CGFloat(i) * 60, height: 100 + CGFloat(i) * 60)
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .opacity(pulse ? 0.3 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: pulse)
            }

            // Core
            Circle()
                .fill(theme.gradient)
                .frame(width: 100, height: 100)
                .shadow(color: theme.primary.opacity(0.8), radius: 25)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )

            // Orbiting notes
            ForEach(0..<4) { i in
                let angle = Double(i) * 90.0
                let radius: CGFloat = 120
                let x = cos(angle * .pi / 180) * radius
                let y = sin(angle * .pi / 180) * radius
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.accent)
                    .offset(x: x, y: y)
            }
        }
        .onAppear { pulse = true }
    }
}
