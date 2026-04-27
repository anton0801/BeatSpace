import SwiftUI

enum NeonTheme: String, CaseIterable, Identifiable, Codable {
    case purple = "Neon Purple"
    case blue = "Neon Blue"
    case pink = "Neon Pink"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .purple: return Color(red: 0.62, green: 0.31, blue: 1.00) // #9E50FF
        case .blue:   return Color(red: 0.25, green: 0.75, blue: 1.00) // #40BFFF
        case .pink:   return Color(red: 1.00, green: 0.31, blue: 0.76) // #FF50C2
        }
    }

    var secondary: Color {
        switch self {
        case .purple: return Color(red: 0.35, green: 0.15, blue: 0.75)
        case .blue:   return Color(red: 0.10, green: 0.45, blue: 0.85)
        case .pink:   return Color(red: 0.80, green: 0.18, blue: 0.55)
        }
    }

    var accent: Color {
        switch self {
        case .purple: return Color(red: 0.90, green: 0.55, blue: 1.00)
        case .blue:   return Color(red: 0.45, green: 0.95, blue: 1.00)
        case .pink:   return Color(red: 1.00, green: 0.55, blue: 0.85)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var radial: RadialGradient {
        RadialGradient(
            colors: [primary.opacity(0.6), .clear],
            center: .center,
            startRadius: 10,
            endRadius: 300
        )
    }

    var symbol: String {
        switch self {
        case .purple: return "sparkles"
        case .blue:   return "waveform.circle"
        case .pink:   return "heart.circle.fill"
        }
    }
}

enum AppBackground {
    static func view(theme: NeonTheme, colorScheme: ColorScheme) -> some View {
        ZStack {
            (colorScheme == .dark ? Color(red: 0.04, green: 0.02, blue: 0.10) : Color(red: 0.95, green: 0.95, blue: 0.99))
                .ignoresSafeArea()

            // Top neon glow
            Circle()
                .fill(theme.primary.opacity(colorScheme == .dark ? 0.35 : 0.22))
                .frame(width: 400, height: 400)
                .blur(radius: 90)
                .offset(x: -120, y: -250)

            // Bottom neon glow
            Circle()
                .fill(theme.accent.opacity(colorScheme == .dark ? 0.30 : 0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .offset(x: 140, y: 320)
        }
    }
}

extension Color {
    static let neonCardDark = Color.white.opacity(0.06)
    static let neonCardLight = Color.black.opacity(0.04)
    static let neonStrokeDark = Color.white.opacity(0.14)
    static let neonStrokeLight = Color.black.opacity(0.10)

    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? neonCardDark : neonCardLight
    }

    static func stroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? neonStrokeDark : neonStrokeLight
    }
}
