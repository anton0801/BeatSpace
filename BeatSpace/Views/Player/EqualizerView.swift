import SwiftUI

struct EqualizerView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.colorScheme) var scheme
    @Environment(\.presentationMode) var presentation

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(settingsVM.theme.gradient)
                                .frame(width: 80, height: 80)
                                .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 20)
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Equalizer")
                            .font(.system(size: 22, weight: .bold))
                        Text("Shape your sound")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Bands
                    HStack(alignment: .bottom, spacing: 12) {
                        BandSlider(value: Binding(get: { settingsVM.equalizer.bass }, set: { settingsVM.setEQBand(0, value: $0) }), label: "60Hz", theme: settingsVM.theme)
                        BandSlider(value: Binding(get: { settingsVM.equalizer.lowMid }, set: { settingsVM.setEQBand(1, value: $0) }), label: "250Hz", theme: settingsVM.theme)
                        BandSlider(value: Binding(get: { settingsVM.equalizer.mid }, set: { settingsVM.setEQBand(2, value: $0) }), label: "1kHz", theme: settingsVM.theme)
                        BandSlider(value: Binding(get: { settingsVM.equalizer.highMid }, set: { settingsVM.setEQBand(3, value: $0) }), label: "4kHz", theme: settingsVM.theme)
                        BandSlider(value: Binding(get: { settingsVM.equalizer.treble }, set: { settingsVM.setEQBand(4, value: $0) }), label: "12kHz", theme: settingsVM.theme)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.card(scheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.stroke(scheme), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)

                    // Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Presets")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(EqualizerSettings.Preset.allCases) { preset in
                                    Button {
                                        Haptics.tap(settingsVM.hapticsOn)
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            settingsVM.applyPreset(preset)
                                        }
                                    } label: {
                                        Text(preset.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(isSelected(preset) ? .white : (scheme == .dark ? .white : .black))
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 10)
                                            .background(
                                                Group {
                                                    if isSelected(preset) { settingsVM.theme.gradient }
                                                    else { Color.card(scheme) }
                                                }
                                            )
                                            .overlay(
                                                Capsule().stroke(Color.stroke(scheme), lineWidth: 1)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    NeonButton(title: "Reset", symbol: "arrow.counterclockwise", theme: settingsVM.theme, filled: false) {
                        Haptics.tap(settingsVM.hapticsOn)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            settingsVM.resetEQ()
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Equalizer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { presentation.wrappedValue.dismiss() }
            }
        }
    }

    private func isSelected(_ preset: EqualizerSettings.Preset) -> Bool {
        EqualizerSettings.from(preset: preset) == settingsVM.equalizer
    }
}

private struct BandSlider: View {
    @Binding var value: Double
    let label: String
    let theme: NeonTheme
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%+.0f", value))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(abs(value) < 0.1 ? .secondary : theme.primary)

            GeometryReader { geo in
                let height = geo.size.height
                let midY = height / 2
                // value range: -12 to +12
                let normalized = (value + 12) / 24.0
                let knobY = height - CGFloat(normalized) * height

                ZStack {
                    // Track
                    Capsule()
                        .fill(Color.stroke(scheme))
                        .frame(width: 4)

                    // Active fill (from middle to knob)
                    Capsule()
                        .fill(theme.gradient)
                        .frame(width: 4, height: abs(midY - knobY))
                        .offset(y: (knobY + midY) / 2 - midY)

                    // Knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: theme.primary.opacity(0.7), radius: 8)
                        .overlay(Circle().stroke(theme.primary, lineWidth: 2))
                        .position(x: geo.size.width / 2, y: knobY)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { g in
                                    let y = min(max(0, g.location.y), height)
                                    let n = 1 - (y / height)
                                    value = Double(n) * 24 - 12
                                }
                        )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 180)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
