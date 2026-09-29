import SwiftUI

/// Campo numerico compatto, coerente con l'estetica del pannello di inserimento.
struct ValueField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    var placeholder: String = "0"
    var width: CGFloat = 96
    var decimals: Int = 2
    var tint: Color = Palette.textPrimary

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Palette.textSecondary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.textTertiary)
                }
            }
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.mono(13, .semibold))
                .foregroundColor(tint)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(width: width)
                .background(fieldBackground)
                .focused($focused)
                .onSubmit(commit)
                .onChange(of: focused) { isFocused in
                    if isFocused { text = Self.format(value, decimals: decimals) }
                }
                .onAppear { text = value > 0 ? Self.format(value, decimals: decimals) : "" }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.black.opacity(0.28))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(focused ? Palette.accent.opacity(0.85) : Palette.stroke,
                                  lineWidth: focused ? 1.5 : 1)
            )
    }

    private func commit() {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        if let parsed = Double(cleaned), parsed >= 0 {
            value = parsed
        }
        text = value > 0 ? Self.format(value, decimals: decimals) : ""
    }

    private static func format(_ v: Double, decimals: Int = 2) -> String {
        if v == 0 { return "" }
        if decimals == 0 || v == v.rounded() {
            return String(format: "%.0f", v)
        }
        return String(format: "%.\(decimals)f", v)
    }
}

/// Campo per il cronometro `hhh:mm:ss` del dispositivo.
struct DurationField: View {
    let title: String
    @Binding var seconds: TimeInterval

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Palette.textSecondary)
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.mono(13, .semibold))
                .foregroundColor(Palette.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(width: 96)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(focused ? Palette.accent.opacity(0.85) : Palette.stroke,
                                              lineWidth: focused ? 1.5 : 1)
                        )
                )
                .focused($focused)
                .onSubmit(commit)
                .onChange(of: focused) { isFocused in
                    if isFocused, seconds > 0 { text = formatDuration(seconds) }
                }
                .onAppear { text = seconds > 0 ? formatDuration(seconds) : "" }
        }
    }

    /// Accetta `h:mm:ss`, `mm:ss` o un numero di secondi.
    private func commit() {
        let parts = text.split(separator: ":").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        if parts.count == 3 {
            seconds = max(0, parts[0] * 3600 + parts[1] * 60 + parts[2])
        } else if parts.count == 2 {
            seconds = max(0, parts[0] * 60 + parts[1])
        } else if parts.count == 1, parts[0] > 0 {
            seconds = parts[0]
        }
        text = seconds > 0 ? formatDuration(seconds) : ""
    }
}
