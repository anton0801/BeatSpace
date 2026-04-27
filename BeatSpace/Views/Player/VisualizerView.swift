import SwiftUI

struct VisualizerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentation

    @State private var t: Double = 0
    @State private var ringScale: CGFloat = 1.0
    private let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [Color.black, settingsVM.theme.primary.opacity(0.3), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Concentric rings
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .stroke(
                            settingsVM.theme.gradient,
                            lineWidth: CGFloat(8 - i)
                        )
                        .frame(width: CGFloat(80 + i * 50), height: CGFloat(80 + i * 50))
                        .scaleEffect(ringScale + CGFloat(i) * 0.04 * CGFloat(playerVM.visualizerAmplitude))
                        .opacity(0.5 - Double(i) * 0.07)
                        .blur(radius: CGFloat(i))
                }
            }

            // Radial bars
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ForEach(0..<64, id: \.self) { i in
                    let angle = Double(i) * (360.0 / 64.0) * .pi / 180
                    let baseR = 150.0
                    let len = 40 + 60 * abs(sin(t * 0.4 + Double(i) * 0.18)) * playerVM.visualizerAmplitude
                    let x1 = center.x + CGFloat(cos(angle) * baseR)
                    let y1 = center.y + CGFloat(sin(angle) * baseR)
                    let x2 = center.x + CGFloat(cos(angle) * (baseR + len))
                    let y2 = center.y + CGFloat(sin(angle) * (baseR + len))
                    Path { p in
                        p.move(to: CGPoint(x: x1, y: y1))
                        p.addLine(to: CGPoint(x: x2, y: y2))
                    }
                    .stroke(settingsVM.theme.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .shadow(color: settingsVM.theme.primary.opacity(0.8), radius: 6)
                }
            }

            // Center orb
            ZStack {
                Circle()
                    .fill(settingsVM.theme.gradient)
                    .frame(width: 90, height: 90)
                    .blur(radius: 14)
                    .opacity(0.7)
                Circle()
                    .fill(settingsVM.theme.gradient)
                    .frame(width: 70, height: 70)
                    .shadow(color: settingsVM.theme.primary, radius: 20)
                if let t = playerVM.currentTrack {
                    Image(systemName: t.mood.symbol)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(1.0 + 0.15 * CGFloat(playerVM.visualizerAmplitude))

            // Bottom waveform
            VStack {
                Spacer()
                NeonWaveform(height: 90, bars: 48)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }

            // Top controls
            VStack {
                HStack {
                    Button {
                        Haptics.tap(settingsVM.hapticsOn)
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    Spacer()
                    Button {
                        Haptics.tap(settingsVM.hapticsOn)
                        playerVM.togglePlay()
                    } label: {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                Spacer()
                if let track = playerVM.currentTrack {
                    VStack(spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(track.artist)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 130)
                } else {
                    Spacer().frame(height: 130)
                }
            }
        }
        .onReceive(timer) { _ in
            if playerVM.isPlaying { t += 0.25 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                ringScale = 1.0 + 0.08 * CGFloat(playerVM.visualizerAmplitude)
            }
        }
        .statusBar(hidden: true)
    }
}
