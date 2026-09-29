import SwiftUI

/// Pannello di immissione dei valori letti sul display del tester BT4-1CHN.
///
/// Le etichette e le sezioni sono organizzate per riflettere esattamente
/// la disposizione visuale a blocchi che l'utente ha davanti sul display:
///
/// 1. Parametri e Menu (in alto a destra sul display):
///    - MODE: AUTO / CHG / DSG
///    - STOP: tensione di fine scarica (es. 2.8 V)
///    - LOOP: cicli (es. 2)
///
/// 2. Valori elettrici (colonna sinistra sul display):
///    - Volt (V) [Rosso]
///    - Ampere (A) [Verde]
///    - Watt (W) [Blu]
///
/// 3. Misure accumulate e diagnostica (centro e fondo display):
///    - Tempo accumulato cronometro hhh:mm:ss [Blu in alto]
///    - Resistenza interna mΩ [Riquadro rosso/arancio]
///    - Capacità mAh [Fascia inferiore]
///    - Energia mWh [Fascia inferiore]
struct SessionInputView: View {
    @Binding var session: TestSession
    let onShowResult: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            cellSection
            settingsSection
            displayMeasurementsSection
            actionBar
        }
    }

    // MARK: - Intestazione

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Trascrizione valori dal display")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                Text("Campi ordinati secondo la disposizione esatta dello schermo del BT4-1CHN")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.textTertiary)
            }
            Spacer()
        }
    }

    // MARK: - 1. Cella in esame

    private var cellSection: some View {
        SectionBox(title: "Cella al litio in prova", symbol: "battery.100percent") {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Formato")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Palette.textSecondary)
                    Picker("", selection: $session.cellType) {
                        ForEach(CellType.allCases) { t in Text(t.title).tag(t) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 145, alignment: .leading)
                }

                ValueField(title: "Capacità nominale", unit: "mAh",
                           value: $session.nominalCapacityMah, width: 115, decimals: 0, tint: Palette.violet)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Riferimento IR sana")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Palette.textSecondary)
                    Text("≤ \(Int(DiagnosisEngine.healthyResistanceMr(for: session.cellType))) mΩ")
                        .font(.mono(13, .semibold))
                        .foregroundColor(Palette.violet)
                    Text("per chimica selezionata")
                        .font(.system(size: 8))
                        .foregroundColor(Palette.textTertiary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 2. Menu Impostazioni della scheda (MODE, STOP, LOOP)

    private var settingsSection: some View {
        SectionBox(title: "Menu della scheda (MODE · STOP · LOOP)", symbol: "slider.horizontal.3") {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MODE (Modalità)")
                        .font(.mono(9, .bold))
                        .foregroundColor(Palette.textTertiary)
                    Picker("MODE", selection: $session.settings.mode) {
                        ForEach(TestMode.allCases) { m in Text(m.title).tag(m) }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .fixedSize()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("STOP").font(.mono(9, .bold)).foregroundColor(Palette.textTertiary)
                        Text(String(format: "%.1f V", session.settings.stopVoltage))
                            .font(.mono(11, .bold)).foregroundColor(Palette.accent)
                    }
                    Picker("STOP", selection: $session.settings.stopVoltage) {
                        ForEach(TestSettings.stopLevels, id: \.self) { level in
                            Text(String(format: "%.1f V", level)).tag(level)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("LOOP").font(.mono(9, .bold)).foregroundColor(Palette.textTertiary)
                        Text("\(session.settings.loopCount)")
                            .font(.mono(11, .bold))
                            .foregroundColor(session.settings.mode == .auto ? Palette.ok : Palette.textTertiary)
                    }
                    Picker("LOOP", selection: $session.settings.loopCount) {
                        ForEach(1...9, id: \.self) { Text("\($0) cicli").tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                    .disabled(session.settings.mode != .auto)
                    .opacity(session.settings.mode == .auto ? 1 : 0.4)
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 3. Valori rilevati a display (organizzati per zone dello schermo)

    private var displayMeasurementsSection: some View {
        SectionBox(title: "Valori a schermo a fine test (STA: END)", symbol: "display") {
            VStack(alignment: .leading, spacing: 14) {
                // Zona 1: Tempo in alto e Resistenza mΩ (colonna destra)
                HStack(alignment: .top, spacing: 16) {
                    DurationField(title: "Tempo cronometro a display (hhh:mm:ss)",
                                  seconds: $session.reading.durationSeconds)

                    ValueField(title: "Resistenza interna (mΩ)", unit: "mΩ",
                               value: $session.reading.internalResistanceMr, width: 110, decimals: 0,
                               tint: Color(red: 1.0, green: 0.45, blue: 0.45))

                    Spacer(minLength: 0)
                }

                Divider().background(Palette.strokeSoft)

                // Zona 2: Colonna sinistra a display (Volt, Ampere, Watt)
                HStack(alignment: .top, spacing: 16) {
                    ValueField(title: "Tensione (V)", unit: "V",
                               value: $session.reading.finalVoltage, width: 95, decimals: 2,
                               tint: Color(red: 1.0, green: 0.35, blue: 0.38))

                    ValueField(title: "Corrente (A)", unit: "A",
                               value: $session.reading.averageCurrent, width: 95, decimals: 2,
                               tint: Color(red: 0.30, green: 0.95, blue: 0.50))

                    ValueField(title: "Potenza (W)", unit: "W",
                               value: $session.reading.powerWatt, width: 95, decimals: 2,
                               tint: Color(red: 0.40, green: 0.75, blue: 1.0))

                    Spacer(minLength: 0)
                }

                Divider().background(Palette.strokeSoft)

                // Zona 3: Barra inferiore a display (Capacità mAh ed Energia mWh)
                HStack(alignment: .top, spacing: 16) {
                    ValueField(title: "Capacità accumulata (mAh)", unit: "mAh",
                               value: $session.reading.capacityMah, width: 120, decimals: 0,
                               tint: Color(red: 0.88, green: 0.65, blue: 1.0))

                    ValueField(title: "Energia accumulata (mWh)", unit: "mWh",
                               value: $session.reading.energyMWh, width: 120, decimals: 0,
                               tint: Color(red: 0.88, green: 0.65, blue: 1.0))

                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Barra di azione

    private var actionBar: some View {
        HStack(spacing: 10) {
            quietButton("Azzera tutto", symbol: "arrow.counterclockwise", action: resetAll)
            quietButton("Carica esempio reale da foto", symbol: "wand.and.stars", action: loadExample)
                .foregroundColor(Palette.accent)
            Spacer(minLength: 0)
            Button(action: onShowResult) {
                Label("Valuta stato batteria", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.black.opacity(0.88))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(LinearGradient(colors: [Palette.accent, Palette.accentDeep],
                                                      startPoint: .leading, endPoint: .trailing))
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }

    private func quietButton(_ title: String, symbol: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Palette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .cardBackground(radius: 9)
        }
        .buttonStyle(.plain)
    }

    private func resetAll() {
        session = TestSession()
    }

    /// Carica l'esempio reale catturato dalla foto del tester fisico:
    /// STOP: 2.8V, AUTO:-END, LOOP:2-2, 2.64V, 0.00A, 0.00W, 138mΩ, 000:15:58
    private func loadExample() {
        session.nominalCapacityMah = 3000
        session.cellType = .liIon18650
        session.settings = TestSettings(mode: .auto, stopVoltage: 2.80, loopCount: 2)
        session.reading = CycleReading(
            index: 1,
            capacityMah: 2450,
            energyMWh: 7600,
            durationSeconds: 15 * 60 + 58, // 15m58s
            internalResistanceMr: 138,
            finalVoltage: 2.64,
            averageCurrent: 0.00,
            powerWatt: 0.00
        )
    }
}
