import SwiftUI

/// Replica pixel-accurate del display TFT a colori da 1,77" del tester BT4-1CHN.
///
/// Layout reale come da foto hardware:
/// ────────────────────────────────────────────────────────
/// [ In alto: Cronometro su fondo blu scuro ] -> 000:15:58
/// ────────────────────────────────────────────────────────
/// [ Colonna Sinistra (Grandi) ] │ [ Colonna Destra (Riquadri) ]
/// 2.64V   (Rosso)               │ AUTO:-END  (Magenta/Viola)
/// 0.00A   (Verde)               │ STOP:2.8V  (Azzurro cyan)
/// 0.00W   (Blu)                 │ LOOP:2-2   (Blu cielo)
///                               │ 0138mΩ     (Rosso/Arancio)
/// ────────────────────────────────────────────────────────
/// [ Barra inferiore ] -> 000000mAh   000000mWh  (Viola/Magenta)
/// ────────────────────────────────────────────────────────
struct DeviceScreenView: View {
    let session: TestSession
    let status: DeviceStatus
    let isPoweredOn: Bool

    private var r: CycleReading { session.reading }

    var body: some View {
        ZStack {
            // Fondo nero dello schermo LCD
            Color(red: 0.01, green: 0.02, blue: 0.03)

            if isPoweredOn {
                VStack(spacing: 0) {
                    // 1. Barra superiore: Cronometro 000:00:00 (su fondo blu)
                    topTimerBar

                    // 2. Griglia centrale: Sinistra (V, A, W) - Destra (AUTO, STOP, LOOP, mΩ)
                    centerGrid

                    // 3. Barra inferiore: 000000mAh  000000mWh (Viola / Magenta)
                    bottomEnergyBar
                }
                .padding(4)
            } else {
                Color.black.opacity(0.88)
            }
        }
        .frame(width: 250, height: 250)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - 1. Barra Cronometro

    private var topTimerBar: some View {
        HStack {
            Text(formattedTimer(r.durationSeconds))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.40, green: 0.75, blue: 1.0))
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(red: 0.04, green: 0.22, blue: 0.65))
        .border(Color(red: 0.2, green: 0.5, blue: 0.95), width: 1)
    }

    // MARK: - 2. Griglia Centrale

    private var centerGrid: some View {
        HStack(spacing: 3) {
            // Colonna Sinistra: V (rosso), A (verde), W (blu)
            VStack(spacing: 3) {
                // Tensione Volt
                leftValueBlock(
                    value: String(format: "%.2f", r.finalVoltage),
                    unit: "V",
                    color: Color(red: 1.0, green: 0.28, blue: 0.32),
                    bg: Color(red: 0.25, green: 0.02, blue: 0.04)
                )

                // Corrente Ampere
                leftValueBlock(
                    value: String(format: "%.2f", r.averageCurrent),
                    unit: "A",
                    color: Color(red: 0.25, green: 0.95, blue: 0.45),
                    bg: Color(red: 0.02, green: 0.20, blue: 0.06)
                )

                // Potenza Watt
                leftValueBlock(
                    value: String(format: "%.2f", r.powerWatt > 0 ? r.powerWatt : (r.finalVoltage * r.averageCurrent)),
                    unit: "W",
                    color: Color(red: 0.35, green: 0.70, blue: 1.0),
                    bg: Color(red: 0.02, green: 0.12, blue: 0.30)
                )
            }
            .frame(maxWidth: .infinity)

            // Colonna Destra: AUTO:-END, STOP:2.8V, LOOP:2-2, Resistenza mΩ
            VStack(spacing: 3) {
                // Modalità e Stato (es. AUTO:-END)
                rightParamBlock(
                    text: "\(session.settings.mode.rawValue):-\(status.rawValue)",
                    color: Color(red: 0.92, green: 0.45, blue: 0.95),
                    bg: Color(red: 0.20, green: 0.02, blue: 0.22)
                )

                // STOP Voltage
                rightParamBlock(
                    text: String(format: "STOP:%.1fV", session.settings.stopVoltage),
                    color: Color(red: 0.40, green: 0.85, blue: 1.0),
                    bg: Color(red: 0.03, green: 0.16, blue: 0.28)
                )

                // LOOP
                rightParamBlock(
                    text: "LOOP:\(session.settings.loopCount)-\(session.settings.loopCount)",
                    color: Color(red: 0.50, green: 0.75, blue: 1.0),
                    bg: Color(red: 0.04, green: 0.14, blue: 0.26)
                )

                // Resistenza Interna mΩ (es. 0138mΩ)
                rightParamBlock(
                    text: formattedResistance(r.internalResistanceMr),
                    color: Color(red: 1.0, green: 0.45, blue: 0.45),
                    bg: Color(red: 0.30, green: 0.05, blue: 0.08)
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 3)
    }

    // MARK: - 3. Barra Inferiore (mAh ed mWh)

    private var bottomEnergyBar: some View {
        HStack(spacing: 4) {
            Text(String(format: "%06.0fmAh", r.capacityMah))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.88, green: 0.65, blue: 1.0))

            Spacer(minLength: 0)

            Text(String(format: "%06.0fmWh", r.energyMWh))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.88, green: 0.65, blue: 1.0))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(red: 0.16, green: 0.04, blue: 0.24))
        .border(Color(red: 0.5, green: 0.2, blue: 0.7), width: 1)
    }

    // MARK: - Blocchi grafici

    private func leftValueBlock(value: String, unit: String, color: Color, bg: Color) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 1) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(bg)
        .border(color.opacity(0.6), width: 1)
    }

    private func rightParamBlock(text: String, color: Color, bg: Color) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(bg)
        .border(color.opacity(0.5), width: 1)
    }

    // MARK: - Formattazione identica al firmware

    private func formattedTimer(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%03d:%02d:%02d", h, m, s)
    }

    private func formattedResistance(_ mr: Double) -> String {
        if mr >= 9999 {
            return "9999mΩ"
        }
        return String(format: "%04.0fmΩ", mr)
    }
}
