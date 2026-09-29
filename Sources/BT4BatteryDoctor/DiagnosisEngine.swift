import Foundation

// MARK: - Esito

/// L'esito complessivo della diagnosi: il semaforo che l'utente cerca.
enum DiagnosisGrade: String {
    case eccellente = "Eccellente"
    case buona = "Buona"
    case accettabile = "Accettabile"
    case degradata = "Degradata"
    case daSostituire = "Da sostituire"

    /// Indice 0 (migliore) ... 4 (peggiore), per il colore e l'ordinamento.
    var severity: Int {
        switch self {
        case .eccellente: return 0
        case .buona: return 1
        case .accettabile: return 2
        case .degradata: return 3
        case .daSostituire: return 4
        }
    }

    var isGood: Bool { severity <= 1 }
}

// MARK: - Diagnosi

/// Il risultato completo dell'analisi di una sessione.
struct Diagnosis {
    let grade: DiagnosisGrade
    /// 0...1: sintesi pesata di tutti i criteri.
    let overallScore: Double
    let nominalMah: Double
    /// Capacità media dei cicli, in mAh.
    let averageCapacityMah: Double
    /// Capacità media in percentuale della nominale.
    let capacityPercent: Double
    /// Differenza percentuale fra il 1° e il 2° ciclo: misura la stabilità della cella.
    let cycleDriftPercent: Double
    let criteria: [Criterion]
    let findings: [Finding]

    /// Etichetta breve dello stato di salute (State of Health).
    var sohLabel: String { "\(Int(capacityPercent.rounded()))% SOH" }

    /// Riepilogo testuale pronto da copiare negli appunti.
    var report: String {
        var lines: [String] = []
        lines.append("DIAGNOSI BATTERIA — 2 CICLI (BT4-1CHN)")
        lines.append("Esito: \(grade.rawValue) — punteggio \(Int((overallScore * 100).rounded()))/100")
        lines.append("")
        lines.append("Capacità nominale: \(Int(nominalMah.rounded())) mAh")
        lines.append("Capacità media misurata: \(Int(averageCapacityMah.rounded())) mAh (\(sohLabel))")
        lines.append("Deriva fra cicli: \(String(format: "%.1f", cycleDriftPercent))%")
        lines.append("")
        lines.append("Criteri:")
        for c in criteria {
            lines.append("• \(c.title): \(c.value) — \(c.detail)")
        }
        if !findings.isEmpty {
            lines.append("")
            lines.append("Annotazioni:")
            for f in findings {
                let mark: String
                switch f.severity {
                case .info: mark = "[i]"
                case .good: mark = "[+]"
                case .warning: mark = "[!]"
                case .critical: mark = "[!!]"
                }
                lines.append("\(mark) \(f.text)")
            }
        }
        return lines.joined(separator: "\n")
    }
}


/// Un singolo criterio valutato, con il suo peso e il valore misurato.
struct Criterion: Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let value: String
    let detail: String
    let weight: Double
    /// 0 = pessimo, 1 = perfetto. Determina il colore del semaforo del criterio.
    let score: Double
    let symbolName: String
}

/// Un avviso o un consiglio operativo emerso dall'analisi.
struct Finding: Identifiable {
    var id = UUID()
    let severity: Severity
    let text: String

    enum Severity { case info, good, warning, critical }
}

// MARK: - Motore di diagnosi

/// Valuta una sessione e produce l'esito dello stato della batteria.
///
/// Il modello segue i quattro parametri che determinano lo stato di una cella li-ion:
///   1. capacità erogata rispetto alla nominale  → SOH (State of Health)
///   2. stabilità fra cicli                        → riproducibilità della misura
///   3. resistenza interna                        → invecchiamento chimico
///   4. rispetto del tempo cronometrato           → qualità della misura
struct DiagnosisEngine {

    /// Soglia di resistenza interna (mΩ) considerata "sana" per formato di cella.
    /// Calibrate su valori tipici di celle nuove: 18650 ≈ 20-40 mΩ, 21700 ≈ 25-50 mΩ.
    static func healthyResistanceMr(for cell: CellType) -> Double {
        switch cell {
        case .liIon18650, .liPo18650: return 45
        case .liIon21700: return 50
        case .liIon26650: return 55
        }
    }

    /// Soglia oltre la quale la resistenza interna è considerata problematica.
    static func criticalResistanceMr(for cell: CellType) -> Double {
        healthyResistanceMr(for: cell) * 2.2
    }

    /// Esegue la diagnosi completa su una sessione.
    static func evaluate(_ session: TestSession) -> Diagnosis {
        let readings = session.readings.filter { $0.capacityMah > 0 }
        // Se la capacità nominale non è stata impostata si ripiega sul tipico del formato,
        // altrimenti il rapporto di salute uscirebbe un valore privo di senso.
        let nominalMissing = session.nominalCapacityMah <= 0
        let nominal = nominalMissing ? session.cellType.typicalNominalMah : session.nominalCapacityMah

        guard !readings.isEmpty else {
            return Diagnosis(
                grade: .daSostituire, overallScore: 0,
                nominalMah: session.nominalCapacityMah,
                averageCapacityMah: 0, capacityPercent: 0, cycleDriftPercent: 0,
                criteria: [],
                findings: [Finding(severity: .info,
                                  text: "Inserisci la capacità in mAh di almeno un ciclo per ottenere la diagnosi.")]
            )
        }

        let averageMah = readings.map(\.capacityMah).reduce(0, +) / Double(readings.count)
        let capacityPercent = averageMah / nominal * 100.0
        let drift = driftPercent(readings)

        var criteria: [Criterion] = []
        var findings: [Finding] = []

        criteria.append(capacityCriterion(averageMah: averageMah, percent: capacityPercent))
        if readings.count >= 2 {
            criteria.append(stabilityCriterion(drift: drift, count: readings.count))
        }
        criteria.append(resistanceCriterion(readings: readings, cell: session.cellType))
        criteria.append(timingCriterion(session: session, readings: readings))

        // ---- Esito sintetico pesato ----
        let totalWeight = criteria.reduce(0) { $0 + $1.weight }
        let weighted = criteria.reduce(0) { $0 + $1.score * $1.weight } / max(totalWeight, 0.0001)

        // La capacità è il criterio dominante: se è bassa l'esito non può essere "buono",
        // anche se gli altri parametri lo permetterebbero.
        var finalGrade: DiagnosisGrade
        switch capacityPercent {
        case 90...: finalGrade = .eccellente
        case 80..<90: finalGrade = .buona
        case 70..<80: finalGrade = .accettabile
        case 55..<70: finalGrade = .degradata
        default: finalGrade = .daSostituire
        }
        // Un punteggio complessivo molto basso demota l'esito di un livello.
        if weighted < 0.55, finalGrade.severity < DiagnosisGrade.degradata.severity {
            finalGrade = .degradata
        }
        if weighted < 0.35, finalGrade.severity < DiagnosisGrade.daSostituire.severity {
            finalGrade = .daSostituire
        }
        // Una deriva oltre il 20% fra più cicli rende la misura inaffidabile.
        if drift > 20, readings.count >= 2, finalGrade.severity < DiagnosisGrade.degradata.severity {
            finalGrade = .degradata
        }

        // ---- Annotazioni contestuali ----
        if drift > 12, readings.count >= 2 {
            findings.append(Finding(severity: .warning,
                text: "I due cicli differiscono del \(String(format: "%.0f", drift))%: la misura non è stabile, la cella non è riproducibile."))
        }
        if averageMah < nominal * 0.6 {
            findings.append(Finding(severity: .critical,
                text: "La cella eroga meno del 60% della capacità nominale: va sostituita."))
        } else if averageMah < nominal * 0.8 {
            findings.append(Finding(severity: .warning,
                text: "Capacità ridotta: adatta i carichi di lavoro o prevedi la sostituzione."))
        } else if averageMah >= nominal * 0.95 {
            findings.append(Finding(severity: .good,
                text: "La cella mantiene praticamente la piena capacità dichiarata."))
        }
        if session.settings.stopVoltage < 2.7 {
            findings.append(Finding(severity: .info,
                text: "Scarica impostata sotto \(String(format: "%.1f", session.settings.stopVoltage)) V: prova profonda, utile per attivare celle ma più stressante."))
        }
        if nominalMissing {
            findings.append(Finding(severity: .info,
                text: "Capacità nominale non impostata: il calcolo usa \(Int(session.cellType.typicalNominalMah)) mAh, il valore tipico delle \(session.cellType.title)."))
        }

        // Coerenza del tempo cronometrato
        let timed = readings.filter { $0.durationSeconds > 0 }
        if !timed.isEmpty, session.nominalCapacityMah > 0 {
            let actualTime = timed[0].durationSeconds
            let isAuto = session.settings.mode == .auto
            let expected = isAuto
                ? TestSession.estimatedAutoTestSeconds(capacityMah: session.nominalCapacityMah, loopCount: session.settings.loopCount)
                : TestSession.estimatedDischargeSeconds(capacityMah: session.nominalCapacityMah)

            let ratio = actualTime / max(expected, 1)
            if ratio < 0.6 || ratio > 1.45 {
                findings.append(Finding(severity: .warning,
                    text: "Il cronometro totale (\(formatDuration(actualTime))) si discosta sensibilmente dalla durata teorica prevista (\(formatDuration(expected))): verifica i dati trascritti."))
            }
        }
        if findings.isEmpty {
            findings.append(Finding(severity: .good, text: "Nessuna anomalia rilevata sui valori inseriti."))
        }

        return Diagnosis(
            grade: finalGrade, overallScore: weighted,
            nominalMah: session.nominalCapacityMah,
            averageCapacityMah: averageMah, capacityPercent: capacityPercent,
            cycleDriftPercent: drift, criteria: criteria, findings: findings
        )
    }



    // MARK: - Criteri singoli

    /// 1) Capacità erogata rispetto alla nominale.
    private static func capacityCriterion(averageMah: Double, percent: Double) -> Criterion {
        let score: Double
        let detail: String
        switch percent {
        case 95...:
            score = 1.00; detail = "piena capacità, cella praticamente nuova"
        case 90..<95:
            score = 0.90; detail = "in ottime condizioni"
        case 80..<90:
            score = 0.78; detail = "usura leggera, normale dopo un uso intenso"
        case 70..<80:
            score = 0.60; detail = "usura evidente, invecchiamento avanzato"
        case 55..<70:
            score = 0.38; detail = "fortemente degradata"
        default:
            score = 0.15; detail = "cella esaurita, fuori specifica"
        }
        return Criterion(
            key: "capacity", title: "Capacità erogata",
            value: "\(Int(averageMah.rounded())) mAh · \(String(format: "%.0f", percent))%",
            detail: detail, weight: 0.40, score: score,
            symbolName: "bolt.batteryblock.fill"
        )
    }

    /// 2) Stabilità della misura fra i cicli.
    private static func driftPercent(_ readings: [CycleReading]) -> Double {
        guard readings.count >= 2 else { return 0 }
        let values = readings.map(\.capacityMah)
        guard let minV = values.min(), let maxV = values.max(), minV > 0 else { return 0 }
        return (maxV - minV) / minV * 100.0
    }

    private static func stabilityCriterion(drift: Double, count: Int) -> Criterion {
        guard count >= 2 else {
            return Criterion(key: "stability", title: "Stabilità fra cicli",
                             value: "n.d.", detail: "serve un secondo ciclo",
                             weight: 0.20, score: 0.5, symbolName: "arrow.triangle.2.circlepath")
        }
        let score: Double = drift <= 3 ? 1.0 : drift <= 6 ? 0.9 : drift <= 12 ? 0.7 : drift <= 20 ? 0.4 : 0.2
        let detail: String = drift <= 3 ? "misure coerenti" :
            drift <= 6 ? "piccola dispersione, normale" :
            drift <= 12 ? "dispersione apprezzabile" :
            "misure molto discordanti"
        return Criterion(key: "stability", title: "Stabilità fra cicli",
                         value: String(format: "±%.1f%%", drift / 2), detail: detail,
                         weight: 0.20, score: score, symbolName: "arrow.triangle.2.circlepath")
    }

    /// 3) Resistenza interna (metodo DC a 2 fili: confronto qualitativo, come da manuale).
    private static func resistanceCriterion(readings: [CycleReading], cell: CellType) -> Criterion {
        let values = readings.map(\.internalResistanceMr).filter { $0 > 0 && $0 < 9999 }
        guard !values.isEmpty else {
            return Criterion(key: "resistance", title: "Resistenza interna",
                             value: "9999 mR", detail: "circuito aperto: batteria non installata",
                             weight: 0.20, score: 0.1, symbolName: "waveform.path.ecg")
        }
        let average = values.reduce(0, +) / Double(values.count)
        let healthy = healthyResistanceMr(for: cell)
        let critical = criticalResistanceMr(for: cell)
        let score: Double = average <= healthy * 0.7 ? 1.0
            : average <= healthy ? 0.88
            : average <= healthy * 1.4 ? 0.70
            : average <= critical * 0.8 ? 0.45 : 0.20
        let detail: String = average <= healthy * 0.7 ? "ottima, cella giovane" :
            average <= healthy ? "normale" :
            average <= healthy * 1.4 ? "in aumento: invecchiamento in corso" :
            average <= critical * 0.8 ? "alta: usura interna significativa" :
            "molto alta: cella fortemente invecchiata"
        return Criterion(key: "resistance", title: "Resistenza interna",
                         value: "\(Int(average.rounded())) mR", detail: detail,
                         weight: 0.20, score: score, symbolName: "waveform.path.ecg")
    }

    /// 4) Coerenza del tempo cronometrato con la modalità di test e la capacità.
    private static func timingCriterion(session: TestSession, readings: [CycleReading]) -> Criterion {
        let withTime = readings.filter { $0.durationSeconds > 0 }
        guard !withTime.isEmpty else {
            return Criterion(key: "timing", title: "Tempo di esecuzione",
                             value: "n.d.", detail: "tempo non inserito",
                             weight: 0.20, score: 0.5, symbolName: "clock.fill")
        }
        let actualTime = withTime[0].durationSeconds
        let isAuto = session.settings.mode == .auto
        let expected = isAuto
            ? TestSession.estimatedAutoTestSeconds(capacityMah: session.nominalCapacityMah, loopCount: session.settings.loopCount)
            : TestSession.estimatedDischargeSeconds(capacityMah: session.nominalCapacityMah)

        let ratio = expected > 0 ? actualTime / expected : 1.0
        let score: Double = (0.7...1.3).contains(ratio) ? 1.0
            : (0.55...1.5).contains(ratio) ? 0.8
            : (0.4...1.8).contains(ratio) ? 0.6 : 0.4
        let detail: String = (0.85...1.2).contains(ratio) ? "tempo totale coerente con il ciclo impostato" :
            ratio < 0.85 ? "durata più rapida del previsto: capacità reale ridotta" :
            "durata più lunga del previsto"
        return Criterion(key: "timing", title: "Tempo accumulato",
                         value: "\(formatDuration(actualTime)) (atteso ≈\(formatDuration(expected)))",
                         detail: detail, weight: 0.20, score: score, symbolName: "clock.fill")
    }
}

// MARK: - Formattazione del cronometro

/// Formato `hhh:mm:ss` identico al cronometro ⑥ del display del dispositivo.
func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(max(0, seconds.rounded()))
    return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
}
