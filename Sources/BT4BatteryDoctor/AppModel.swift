import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Stato dell'applicazione: i dati della sessione e le azioni di esportazione.
final class AppModel: ObservableObject {
    @Published var session = TestSession()
    @Published var status: DeviceStatus = .end
    @Published var isPoweredOn: Bool = true
    @Published var diagnosis: Diagnosis = DiagnosisEngine.evaluate(TestSession())

    func updateDiagnosis() {
        diagnosis = DiagnosisEngine.evaluate(session)
    }

    // MARK: Esportazione

    func copyReport() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(diagnosis.report, forType: .string)
    }

    func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "diagnosi-batteria.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        panel.message = "Salva il riepilogo della diagnosi"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        var rows: [[String]] = []
        rows.append(["Diagnosi batteria tester BT4-1CHN"])
        rows.append(["Generata il", ISO8601DateFormatter().string(from: Date())])
        rows.append([])
        rows.append(["Esito", diagnosis.grade.rawValue])
        rows.append(["Punteggio", String(format: "%.0f/100", diagnosis.overallScore * 100)])
        rows.append(["Capacita nominale (mAh)", String(format: "%.0f", diagnosis.nominalMah)])
        rows.append(["Capacita scaricata (mAh)", String(format: "%.0f", diagnosis.averageCapacityMah)])
        rows.append(["SOH (%)", String(format: "%.1f", diagnosis.capacityPercent)])
        rows.append([])
        rows.append(["Parametro", "Valore a display", "Unita"])
        let r = session.reading
        rows.append(["Tensione a riposo/fine scarica", String(format: "%.3f", r.finalVoltage), "V"])
        rows.append(["Corrente", String(format: "%.2f", r.averageCurrent), "A"])
        rows.append(["Potenza", String(format: "%.2f", r.powerWatt), "W"])
        rows.append(["Capacita scarica", String(format: "%.0f", r.capacityMah), "mAh"])
        rows.append(["Energia scarica", String(format: "%.0f", r.energyMWh), "mWh"])
        rows.append(["Tempo accumulato", formatDuration(r.durationSeconds), "hhh:mm:ss"])
        rows.append(["Resistenza interna", String(format: "%.0f", r.internalResistanceMr), "mR"])
        rows.append([])
        rows.append(["Modalita (MODE)", session.settings.mode.rawValue, ""])
        rows.append(["Tensione di stop (STOP)", String(format: "%.1f", session.settings.stopVoltage), "V"])
        rows.append(["Cicli (LOOP)", "\(session.settings.loopCount)", ""])
        rows.append([])
        rows.append(["Criterio", "Valore", "Dettaglio", "Punteggio"])
        for c in diagnosis.criteria {
            rows.append([c.title, c.value, c.detail, String(format: "%.2f", c.score)])
        }
        rows.append([])
        rows.append(["Annotazioni", "", "", ""])
        for f in diagnosis.findings {
            rows.append([f.text, "", "", ""])
        }

        let csv = rows.map { $0.map(csvEscape).joined(separator: ";") }.joined(separator: "\n")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private func csvEscape(_ field: String) -> String {
        if field.contains(";") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
