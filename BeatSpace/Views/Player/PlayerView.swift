import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var musicVM: MusicViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme
    @Environment(\.presentationMode) var presentation

    @State private var showQueue = false
    @State private var showEQ = false
    @State private var showVisualizer = false
    @State private var showSleepTimer = false
    @State private var dragOffset: CGFloat = 0
    @State private var isSeeking = false
    @State private var seekProgress: Double = 0

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)
                .ignoresSafeArea()

            if let track = playerVM.currentTrack {
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        cover(track: track)
                        titleBlock(track: track)
                        NeonWaveform(height: 70)
                            .padding(.horizontal, 24)
                        progressBlock
                        primaryControls
                        extraControls
                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(settingsVM.theme.primary)
                    Text("No track loaded")
                        .font(.headline)
                    NeonButton(title: "Close", theme: settingsVM.theme, filled: false) {
                        presentation.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { v in
                    if v.translation.height > 0 { dragOffset = v.translation.height }
                }
                .onEnded { v in
                    if v.translation.height > 140 {
                        presentation.wrappedValue.dismiss()
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
        )
        .sheet(isPresented: $showQueue) { QueueSheet() }
        .sheet(isPresented: $showEQ) {
            NavigationView { EqualizerView() }
                .accentColor(settingsVM.theme.primary)
        }
        .sheet(isPresented: $showSleepTimer) {
            NavigationView { SleepTimerView() }
                .accentColor(settingsVM.theme.primary)
        }
        .fullScreenCover(isPresented: $showVisualizer) {
            VisualizerView()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            NeonIconButton(symbol: "chevron.down", theme: settingsVM.theme) {
                Haptics.tap(settingsVM.hapticsOn)
                presentation.wrappedValue.dismiss()
            }
            Spacer()
            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                if let m = playerVM.currentTrack?.mood {
                    Text(m.title.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(settingsVM.theme.primary)
                }
            }
            Spacer()
            NeonIconButton(symbol: "list.bullet", theme: settingsVM.theme) {
                Haptics.tap(settingsVM.hapticsOn)
                showQueue = true
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: Cover

    private func cover(track: Track) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(track.coverGradient)
                .shadow(color: track.coverColors.first?.opacity(0.6) ?? .clear, radius: 40, x: 0, y: 20)

            // Decorative motif
            VStack {
                HStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .blur(radius: 6)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .blur(radius: 8)
                }
            }
            .padding(20)

            Image(systemName: track.mood.symbol)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(width: 300, height: 300)
        .scaleEffect(playerVM.isPlaying ? 1.0 : 0.94)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playerVM.isPlaying)
        .onTapGesture {
            Haptics.tap(settingsVM.hapticsOn)
            showVisualizer = true
        }
    }

    // MARK: Title + actions

    private func titleBlock(track: Track) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(2)
                Text(track.artist)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    PillTag(title: track.genre, theme: settingsVM.theme)
                    PillTag(title: "\(track.bpm) BPM", theme: settingsVM.theme)
                }
                .padding(.top, 4)
            }
            Spacer()
            Button {
                Haptics.tap(settingsVM.hapticsOn)
                musicVM.toggleFavorite(track.id)
            } label: {
                Image(systemName: musicVM.isFavorite(track.id) ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(musicVM.isFavorite(track.id) ? settingsVM.theme.accent : .secondary)
                    .scaleEffect(musicVM.isFavorite(track.id) ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: musicVM.isFavorite(track.id))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Progress

    private var progressBlock: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let p = isSeeking ? seekProgress : playerVM.progress
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.stroke(scheme))
                        .frame(height: 4)
                    Capsule()
                        .fill(settingsVM.theme.gradient)
                        .frame(width: max(0, geo.size.width * CGFloat(p)), height: 4)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: settingsVM.theme.primary.opacity(0.7), radius: 6)
                        .offset(x: max(0, geo.size.width * CGFloat(p) - 7))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            isSeeking = true
                            seekProgress = min(1, max(0, Double(v.location.x / geo.size.width)))
                        }
                        .onEnded { _ in
                            playerVM.seek(to: seekProgress)
                            isSeeking = false
                        }
                )
            }
            .frame(height: 18)

            HStack {
                Text(formatTime(playerVM.elapsed))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if let t = playerVM.currentTrack {
                    Text("-" + formatTime(max(0, t.durationSeconds - playerVM.elapsed)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: Primary Controls

    private var primaryControls: some View {
        HStack(spacing: 28) {
            Button {
                Haptics.tap(settingsVM.hapticsOn)
                playerVM.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(playerVM.shuffle ? settingsVM.theme.primary : .secondary)
            }
            .buttonStyle(.plain)

            NeonIconButton(symbol: "backward.fill", theme: settingsVM.theme, size: 52) {
                Haptics.tap(settingsVM.hapticsOn)
                playerVM.previous()
            }

            Button {
                Haptics.tap(settingsVM.hapticsOn, style: .medium)
                playerVM.togglePlay()
            } label: {
                ZStack {
                    Circle()
                        .fill(settingsVM.theme.gradient)
                        .frame(width: 78, height: 78)
                        .shadow(color: settingsVM.theme.primary.opacity(0.6), radius: 20, x: 0, y: 10)
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: playerVM.isPlaying ? 0 : 2)
                }
                .scaleEffect(playerVM.isPlaying ? 1.0 : 0.97)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playerVM.isPlaying)
            }
            .buttonStyle(.plain)

            NeonIconButton(symbol: "forward.fill", theme: settingsVM.theme, size: 52) {
                Haptics.tap(settingsVM.hapticsOn)
                playerVM.next()
            }

            Button {
                Haptics.tap(settingsVM.hapticsOn)
                playerVM.cycleRepeat()
            } label: {
                Image(systemName: playerVM.repeatMode.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(playerVM.repeatMode != .off ? settingsVM.theme.primary : .secondary)
                    .overlay(
                        Group {
                            if playerVM.repeatMode == .all {
                                Circle()
                                    .fill(settingsVM.theme.primary)
                                    .frame(width: 4, height: 4)
                                    .offset(y: 14)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Extras

    private var extraControls: some View {
        VStack(spacing: 16) {
            // Volume
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                Slider(value: $playerVM.volume, in: 0...1)
                    .accentColor(settingsVM.theme.primary)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 10) {
                ExtraButton(symbol: "slider.horizontal.3", label: "EQ", theme: settingsVM.theme) {
                    Haptics.tap(settingsVM.hapticsOn)
                    showEQ = true
                }
                ExtraButton(
                    symbol: "moon.zzz.fill",
                    label: playerVM.sleepMinutes > 0 ? sleepLabel() : "Sleep",
                    theme: settingsVM.theme,
                    active: playerVM.sleepMinutes > 0
                ) {
                    Haptics.tap(settingsVM.hapticsOn)
                    showSleepTimer = true
                }
                ExtraButton(symbol: "waveform", label: "Visual", theme: settingsVM.theme) {
                    Haptics.tap(settingsVM.hapticsOn)
                    showVisualizer = true
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func sleepLabel() -> String {
        let m = playerVM.sleepSecondsLeft / 60
        let s = playerVM.sleepSecondsLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct OfflineView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("splash_lcl")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 2)
                    .opacity(0.8)
                
                Image("beat_space_problem")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}
private struct ExtraButton: View {
    let symbol: String
    let label: String
    let theme: NeonTheme
    var active: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(active ? .white : (scheme == .dark ? .white : .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if active { theme.gradient }
                    else { Color.card(scheme) }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.stroke(scheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: active ? theme.primary.opacity(0.4) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Queue Sheet

struct QueueSheet: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentation
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)
                if playerVM.queue.isEmpty {
                    EmptyStateView(symbol: "music.note.list", title: "Queue is empty", message: "Play something to see tracks here")
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(playerVM.queue.enumerated()), id: \.element.id) { _, t in
                                TrackRow(track: t, queue: playerVM.queue)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentation.wrappedValue.dismiss() }
                }
            }
        }
        .accentColor(settingsVM.theme.primary)
    }
}
