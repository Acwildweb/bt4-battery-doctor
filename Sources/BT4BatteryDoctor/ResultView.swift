import SwiftUI

/// Contenitore a sezione con intestazione, usato al posto di `GroupBox`
/// per avere un controllo pieno dello stile nel tema scuro.
struct SectionBox<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Palette.textSecondary)
            content
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(radius: 12)
    }
}

/// Colore associato a un esito, usato dal semaforo finale.
extension DiagnosisGrade {
    var color: Color {
        switch self {
        case .eccellente: return Palette.ok
        case .buona: return Color(red: 0.55, green: 0.85, blue: 0.45)
        case .accettabile: return Palette.warn
        case .degradata: return Color(red: 1.00, green: 0.55, blue: 0.30)
        case .daSostituire: return Palette.danger
        }
    }

    var symbolName: String {
        switch self {
        case .eccellente: return "checkmark.seal.fill"
        case .buona: return "checkmark.circle.fill"
        case .accettabile: return "exclamationmark.circle.fill"
        case .degradata: return "exclamationmark.triangle.fill"
        case .daSostituire: return "xmark.octagon.fill"
        }
    }
}

/// Colore di un punteggio 0...1.
func scoreColor(_ score: Double) -> Color {
    switch score {
    case 0.8...: return Palette.ok
    case 0.6..<0.8: return Color(red: 0.70, green: 0.88, blue: 0.45)
    case 0.4..<0.6: return Palette.warn
    default: return Palette.danger
    }
}

/// Pannello con l'esito dello stato della batteria.
struct ResultView: View {
    let diagnosis: Diagnosis
    let onCopy: () -> Void
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headline
            metricsRow
            criteriaList
            findingsList
            footerActions
        }
    }

    // MARK: Esito principale

    private var headline: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [diagnosis.grade.color.opacity(0.35), .clear],
                                         center: .center, startRadius: 4, endRadius: 44))
                    .frame(width: 88, height: 88)
                Image(systemName: diagnosis.grade.symbolName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(diagnosis.grade.color)
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 4) {
                Text("ESITO DIAGNOSI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Palette.textTertiary)
                    .kerning(1.4)
                Text(diagnosis.grade.rawValue)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(diagnosis.grade.color)
                Text(summary)
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                scoreGauge
                Text("punteggio")
                    .font(.system(size: 8.5))
                    .foregroundColor(Palette.textTertiary)
            }
        }
        .padding(16)
        .cardBackground(radius: 16, fill: Palette.cardStrong)
    }

    private var summary: String {
        if diagnosis.averageCapacityMah <= 0 {
            return "Nessun dato valido: inserisci la capacità di almeno un ciclo."
        }
        return "La cella eroga \(Int(diagnosis.averageCapacityMah.rounded())) mAh su \(Int(diagnosis.nominalMah.rounded())) mAh nominali (\(diagnosis.sohLabel))."
    }

    private var scoreGauge: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(0.02, diagnosis.overallScore))
                .stroke(scoreColor(diagnosis.overallScore),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((diagnosis.overallScore * 100).rounded()))")
                .font(.mono(18, .bold))
                .foregroundColor(Palette.textPrimary)
        }
        .frame(width: 62, height: 62)
    }

    // MARK: Metriche riassuntive

    private var metricsRow: some View {
        HStack(spacing: 10) {
            metricCard(title: "Capacità scaricata",
                       value: "\(Int(diagnosis.averageCapacityMah.rounded()))",
                       unit: "mAh", tint: Palette.accent)
            metricCard(title: "Stato di salute",
                       value: "\(Int(diagnosis.capacityPercent.rounded()))",
                       unit: "%", tint: scoreColor(diagnosis.capacityPercent / 100))
            if diagnosis.cycleDriftPercent > 0 {
                metricCard(title: "Deriva cicli",
                           value: String(format: "%.1f", diagnosis.cycleDriftPercent),
                           unit: "%", tint: diagnosis.cycleDriftPercent <= 6 ? Palette.ok : Palette.warn)
            } else {
                metricCard(title: "Cella",
                           value: "\(Int(diagnosis.nominalMah.rounded()))",
                           unit: "mAh nom.", tint: Palette.ok)
            }
            metricCard(title: "Criteri conformi",
                       value: "\(diagnosis.criteria.filter { $0.score >= 0.7 }.count)",
                       unit: "/ \(max(diagnosis.criteria.count, 1))", tint: Palette.violet)
        }
    }

    private func metricCard(title: String, value: String, unit: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(Palette.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.mono(21, .bold)).foregroundColor(tint)
                Text(unit).font(.mono(10, .semibold)).foregroundColor(tint.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cardBackground(radius: 12)
    }

    // MARK: Criteri

    private var criteriaList: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Criteri di valutazione")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Palette.textSecondary)
            ForEach(diagnosis.criteria) { criterion in
                criterionRow(criterion)
            }
        }
    }

    private func criterionRow(_ c: Criterion) -> some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: c.symbolName)
                .font(.system(size: 13))
                .foregroundColor(scoreColor(c.score))
                .frame(width: 24, height: 24)
                .background(Circle().fill(scoreColor(c.score).opacity(0.12)))

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(c.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Palette.textPrimary)
                    Text("peso \(Int(c.weight * 100))%")
                        .font(.system(size: 8.5))
                        .foregroundColor(Palette.textTertiary)
                }
                Text(c.detail)
                    .font(.system(size: 10))
                    .foregroundColor(Palette.textTertiary)
            }

            Spacer(minLength: 8)
            Text(c.value)
                .font(.mono(11, .semibold))
                .foregroundColor(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 150, alignment: .trailing)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07)).frame(width: 54, height: 5)
                Capsule().fill(scoreColor(c.score)).frame(width: 54 * max(0.03, c.score), height: 5)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .cardBackground(radius: 10)
    }

    // MARK: Annotazioni

    private var findingsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(diagnosis.findings) { finding in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: symbol(for: finding.severity))
                        .font(.system(size: 11))
                        .foregroundColor(color(for: finding.severity))
                    Text(finding.text)
                        .font(.system(size: 11))
                        .foregroundColor(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func symbol(for severity: Finding.Severity) -> String {
        switch severity {
        case .info: return "info.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private func color(for severity: Finding.Severity) -> Color {
        switch severity {
        case .info: return Palette.accent
        case .good: return Palette.ok
        case .warning: return Palette.warn
        case .critical: return Palette.danger
        }
    }

    // MARK: Azioni finali

    private var footerActions: some View {
        HStack(spacing: 10) {
            smallButton("Copia riepilogo", symbol: "doc.on.doc", action: onCopy)
            smallButton("Esci CSV", symbol: "tablecells", action: onExport)
            Spacer(minLength: 0)
            Text("Metodo DC a 2 fili: valori qualitativi, come da manuale del dispositivo.")
                .font(.system(size: 9.5))
                .foregroundColor(Palette.textTertiary)
        }
    }

    private func smallButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
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
}
