import SwiftUI

/// Palette unica dell'app: tema "strumento di laboratorio" scuro con LCD verde fosforescente,
/// in modo che il display del dispositivo resti leggibile e dominante.
enum Palette {
    static let bgTop = Color(red: 0.035, green: 0.043, blue: 0.070)
    static let bgMid = Color(red: 0.062, green: 0.078, blue: 0.118)
    static let bgBottom = Color(red: 0.031, green: 0.039, blue: 0.063)

    static let card = Color.white.opacity(0.055)
    static let cardStrong = Color.white.opacity(0.085)
    static let stroke = Color.white.opacity(0.10)
    static let strokeSoft = Color.white.opacity(0.06)
    static let hairline = Color.white.opacity(0.14)

    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.40)

    static let accent = Color(red: 0.42, green: 0.80, blue: 1.00)
    static let accentDeep = Color(red: 0.16, green: 0.45, blue: 0.80)

    static let ok = Color(red: 0.29, green: 0.85, blue: 0.60)
    static let warn = Color(red: 1.00, green: 0.75, blue: 0.29)
    static let danger = Color(red: 1.00, green: 0.42, blue: 0.40)
    static let violet = Color(red: 0.68, green: 0.60, blue: 1.00)

    /// Colori del pannello LCD del dispositivo.
    enum LCD {
        static let background = Color(red: 0.043, green: 0.086, blue: 0.063)
        static let bezel = Color(red: 0.078, green: 0.082, blue: 0.090)
        static let ink = Color(red: 0.60, green: 1.00, blue: 0.70)
        static let inkDim = Color(red: 0.36, green: 0.68, blue: 0.45)
        static let inkFaint = Color(red: 0.24, green: 0.50, blue: 0.32)
        static let glow = Color(red: 0.30, green: 1.00, blue: 0.55)
    }

    /// Colori del guscio del dispositivo (plastica grigio scuro).
    enum Shell {
        static let body = Color(red: 0.145, green: 0.150, blue: 0.165)
        static let bodyHi = Color(red: 0.205, green: 0.212, blue: 0.232)
        static let bodyLo = Color(red: 0.086, green: 0.090, blue: 0.104)
        static let rubber = Color(red: 0.062, green: 0.066, blue: 0.078)
    }
}

extension Font {
    /// Cifre tabellari per i pannelli numerici (allineamento verticale stabile).
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    func cardBackground(radius: CGFloat = 14, fill: Color = Palette.card) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Palette.stroke, lineWidth: 1)
                )
        )
    }

    func softShadow(_ strength: CGFloat = 0.35, _ radius: CGFloat = 18, y: CGFloat = 8) -> some View {
        shadow(color: Color.black.opacity(strength), radius: radius, x: 0, y: y)
    }
}
