import SwiftUI

struct SleepTimerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentation
    @Environment(\.colorScheme) var scheme

    private let options: [Int] = [5, 10, 15, 30, 45, 60]

    var body: some View {
        ZStack {
            AppBackground.view(theme: settingsVM.theme, colorScheme: scheme)

            if playerVM.sleepMinutes > 0 {
                activeView
            } else {
                pickerView
            }
        }
        .navigationTitle("Sleep Timer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentation.wrappedValue.dismiss() }
            }
        }
    }

    private var pickerView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(settingsVM.theme.gradient)
                            .frame(width: 80, height: 80)
                            .shadow(color: settingsVM.theme.primary.opacity(0.5), radius: 20)
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Sleep Timer")
                        .font(.system(size: 22, weight: .bold))
                    Text("Music will stop automatically")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options, id: \.self) { m in
                        Button {
                            Haptics.tap(settingsVM.hapticsOn, style: .medium)
                            playerVM.startSleepTimer(minutes: m)
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(m)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(settingsVM.theme.primary)
                                Text("minutes")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.card(scheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.stroke(scheme), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
        }
    }

    private var activeView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.stroke(scheme), lineWidth: 12)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        settingsVM.theme.gradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                    .shadow(color: settingsVM.theme.primary.opacity(0.7), radius: 16)
                    .animation(.linear(duration: 1), value: playerVM.sleepSecondsLeft)

                VStack(spacing: 4) {
                    Text(formatted)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(settingsVM.theme.primary)
                    Text("remaining")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(.secondary)
                }
            }

            Text("Pauses music when timer ends")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            NeonButton(title: "Cancel Timer", symbol: "xmark", theme: settingsVM.theme, filled: false) {
                Haptics.tap(settingsVM.hapticsOn)
                playerVM.stopSleepTimer()
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var progress: CGFloat {
        let total = playerVM.sleepMinutes * 60
        guard total > 0 else { return 0 }
        return CGFloat(playerVM.sleepSecondsLeft) / CGFloat(total)
    }

    private var formatted: String {
        let m = playerVM.sleepSecondsLeft / 60
        let s = playerVM.sleepSecondsLeft % 60
        return String(format: "%d:%02d", m, s)
    }
}
