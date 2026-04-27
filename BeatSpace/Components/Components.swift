import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var scheme
    let content: Content
    var padding: CGFloat = 16
    var radius: CGFloat = 20

    init(padding: CGFloat = 16, radius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.card(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.stroke(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Neon Button

struct NeonButton: View {
    let title: String
    var symbol: String? = nil
    var theme: NeonTheme
    var filled: Bool = true
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 10) {
                if let s = symbol { Image(systemName: s) }
                Text(title).fontWeight(.semibold)
            }
            .font(.system(size: 16))
            .foregroundColor(filled ? .white : theme.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if filled {
                        theme.gradient
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(filled ? Color.white.opacity(0.15) : theme.primary, lineWidth: filled ? 1 : 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: filled ? theme.primary.opacity(0.45) : .clear, radius: 18, x: 0, y: 8)
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Button

struct NeonIconButton: View {
    let symbol: String
    var theme: NeonTheme
    var size: CGFloat = 44
    var active: Bool = false
    var action: () -> Void

    @Environment(\.colorScheme) var scheme
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { pressed = false }
            }
            action()
        }) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(active ? .white : (scheme == .dark ? .white : .black))
                .frame(width: size, height: size)
                .background(
                    Circle().fill(active ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.card(scheme)))
                )
                .overlay(Circle().stroke(Color.stroke(scheme), lineWidth: 1))
                .scaleEffect(pressed ? 0.9 : 1.0)
                .shadow(color: active ? theme.primary.opacity(0.5) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Field

struct NeonTextField: View {
    let placeholder: String
    @Binding var text: String
    var symbol: String
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default
    var theme: NeonTheme

    @Environment(\.colorScheme) var scheme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(isFocused ? theme.primary : .secondary)
                .frame(width: 22)
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .focused($isFocused)
            .font(.system(size: 16))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.card(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isFocused ? theme.primary : Color.stroke(scheme), lineWidth: isFocused ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Track Row

struct TrackRow: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme

    let track: Track
    var queue: [Track]? = nil
    var showFav: Bool = true
    var showDownload: Bool = false
    var trailing: AnyView? = nil

    var isPlaying: Bool { playerVM.currentTrack?.id == track.id && playerVM.isPlaying }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(track.coverGradient)
                    .frame(width: 54, height: 54)
                if isPlaying {
                    PlayingBars(color: .white)
                } else {
                    Image(systemName: track.mood.symbol)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 20, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(isPlaying ? settingsVM.theme.primary : (scheme == .dark ? .white : .black))
                HStack(spacing: 6) {
                    Text(track.artist).font(.system(size: 12)).foregroundColor(.secondary)
                    Text("•").foregroundColor(.secondary).font(.system(size: 12))
                    Text(track.duration).font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            Spacer()

            if showFav {
                Button {
                    musicVM.toggleFavorite(track.id)
                } label: {
                    Image(systemName: musicVM.isFavorite(track.id) ? "heart.fill" : "heart")
                        .foregroundColor(musicVM.isFavorite(track.id) ? settingsVM.theme.primary : .secondary)
                }
                .buttonStyle(.plain)
            }

            if showDownload {
                Button {
                    musicVM.toggleDownload(track.id)
                } label: {
                    Image(systemName: musicVM.isDownloaded(track.id) ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .foregroundColor(musicVM.isDownloaded(track.id) ? settingsVM.theme.primary : .secondary)
                }
                .buttonStyle(.plain)
            }

            if let t = trailing { t }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.card(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.stroke(scheme), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let q = queue ?? [track]
            playerVM.load(track: track, queue: q)
        }
    }
}

// MARK: - Playing Bars Indicator

struct PlayingBars: View {
    var color: Color = .white
    @State private var phase: CGFloat = 0
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: barHeight(i))
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { phase += 1 }
        }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        let vals: [CGFloat] = [12, 18, 10, 16, 8, 20, 14]
        let idx = (Int(phase) + i * 2) % vals.count
        return vals[idx]
    }
}

// MARK: - Neon Waveform

struct NeonWaveform: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    var height: CGFloat = 80
    var bars: Int = 42

    @State private var t: Double = 0
    private let timer = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<bars, id: \.self) { i in
                let normalized = wave(for: i)
                Capsule()
                    .fill(settingsVM.theme.gradient)
                    .frame(width: 3, height: max(4, height * normalized))
                    .shadow(color: settingsVM.theme.primary.opacity(0.6), radius: 4)
            }
        }
        .frame(height: height)
        .onReceive(timer) { _ in
            if playerVM.isPlaying { t += 0.35 }
        }
    }

    private func wave(for i: Int) -> CGFloat {
        let base = 0.25 + 0.75 * abs(sin(t * 0.3 + Double(i) * 0.35))
        let amp = playerVM.isPlaying ? playerVM.visualizerAmplitude : 0.25
        return CGFloat(base * amp)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack {
            Text(title).font(.system(size: 19, weight: .bold))
            Spacer()
            if let a = actionTitle, let act = action {
                Button(action: act) {
                    Text(a)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(settingsVM.theme.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Pill Tag

struct PillTag: View {
    let title: String
    var symbol: String? = nil
    var active: Bool = false
    var theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 6) {
            if let s = symbol { Image(systemName: s).font(.system(size: 12)) }
            Text(title).font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(active ? .white : (scheme == .dark ? .white : .black))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(active ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.card(scheme)))
        )
        .overlay(Capsule().stroke(Color.stroke(scheme), lineWidth: 1))
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(settingsVM.theme.primary.opacity(0.18)).frame(width: 96, height: 96)
                Image(systemName: symbol)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(settingsVM.theme.primary)
            }
            Text(title).font(.system(size: 18, weight: .bold))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Haptics helper

enum Haptics {
    static func tap(_ on: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard on else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ on: Bool, type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        guard on else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
