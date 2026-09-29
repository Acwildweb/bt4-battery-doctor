import Foundation

/// Auto-verifica della logica di diagnosi, eseguibile da terminale con `--selftest`.
///
/// Serve a validare il motore senza aprire l'interfaccia: ogni caso reale di
/// batteria (sana, affaticata, esausta, dati incompleti) deve produrre l'esito atteso.
enum SelfTest {

    /// Esegue il test se richiesto dalla riga di comando.
    /// - Returns: `true` se il programma deve terminare (modalità test).
    static func runIfNeeded() -> Bool {
        guard CommandLine.arguments.contains("--selftest") else { return false }
        let failures = run()
        exit(failures == 0 ? 0 : 1)
    }

    // MARK: Casi di prova

    private struct Fixture {
        let name: String
        let session: TestSession
        /// Esito minimo atteso (peggiore tollerato).
        let worstAllowed: DiagnosisGrade
        /// Esito massimo atteso (migliore tollerato).
        let bestAllowed: DiagnosisGrade
        /// Se impostato, fra le annotazioni deve comparirne una che contiene questa frase.
        var expectFinding: String? = nil
    }

    private static func session(nominal: Double,
                                cell: CellType = .liIon18650,
                                mah: Double,
                                mwh: Double,
                                ir: Double,
                                seconds: TimeInterval,
                                v: Double = 3.0,
                                a: Double = 0.95,
                                w: Double = 2.85) -> TestSession {
        var s = TestSession()
        s.nominalCapacityMah = nominal
        s.cellType = cell
        s.settings = TestSettings(mode: .auto, stopVoltage: 2.80, loopCount: 1)
        s.reading = CycleReading(
            index: 1,
            capacityMah: mah,
            energyMWh: mwh,
            durationSeconds: seconds > 0 ? seconds : TestSession.estimatedAutoTestSeconds(capacityMah: mah, loopCount: 1),
            internalResistanceMr: ir,
            finalVoltage: v,
            averageCurrent: a,
            powerWatt: w
        )
        return s
    }

    private static var fixtures: [Fixture] {
        [
            Fixture(
                name: "Cella quasi nuova (98% SOH, IR 32 mR)",
                session: session(nominal: 3000, mah: 2950, mwh: 9500, ir: 32, seconds: 15900),
                worstAllowed: .buona, bestAllowed: .eccellente),

            Fixture(
                name: "Cella invecchiata in modo uniforme (80% SOH, IR 58 mR)",
                session: session(nominal: 3000, mah: 2400, mwh: 7450, ir: 58, seconds: 13000),
                worstAllowed: .accettabile, bestAllowed: .buona),

            Fixture(
                name: "Cella affaticata e degradata (65% SOH, IR 85 mR)",
                session: session(nominal: 3000, mah: 1950, mwh: 5700, ir: 85, seconds: 10500),
                worstAllowed: .daSostituire, bestAllowed: .degradata),

            Fixture(
                name: "Cella esausta (26% SOH, IR 240 mR)",
                session: session(nominal: 3000, mah: 780, mwh: 2050, ir: 240, seconds: 4200),
                worstAllowed: .daSostituire, bestAllowed: .daSostituire),

            Fixture(
                name: "Cronometro incoerente con la capacità (tempo troppo breve)",
                session: shortTimeSession(),
                worstAllowed: .accettabile, bestAllowed: .eccellente,
                expectFinding: "discosta sensibilmente"),

            Fixture(
                name: "21700 da 4000 mAh sana",
                session: session(nominal: 4000, cell: .liIon21700, mah: 3910, mwh: 13080, ir: 28, seconds: 21200),
                worstAllowed: .buona, bestAllowed: .eccellente),

            Fixture(
                name: "Dati non ancora inseriti (non deve andare in crash)",
                session: TestSession(),
                worstAllowed: .daSostituire, bestAllowed: .daSostituire),

            Fixture(
                name: "Capacità nominale assente (nessuna divisione per zero)",
                session: session(nominal: 0, mah: 1500, mwh: 4600, ir: 60, seconds: 8100),
                worstAllowed: .daSostituire, bestAllowed: .eccellente,
                expectFinding: "nominale non impostata")
        ]
    }

    /// Cella sana ma con il cronometro trascritto male: il motore deve segnalarlo.
    private static func shortTimeSession() -> TestSession {
        session(nominal: 3000, mah: 2900, mwh: 9300, ir: 35, seconds: 2500)
    }

    // MARK: Esecuzione

    @discardableResult
    static func run() -> Int {
        print("BT4 Battery Doctor — auto-verifica del motore di diagnosi")
        print(String(repeating: "─", count: 78))
        var failures = 0

        for f in fixtures {
            let d = DiagnosisEngine.evaluate(f.session)
            var ok = d.grade.severity <= f.worstAllowed.severity
                && d.grade.severity >= f.bestAllowed.severity
            if let needle = f.expectFinding,
               !d.findings.contains(where: { $0.text.contains(needle) }) {
                ok = false
            }
            if !ok { failures += 1 }

            print("\(ok ? "✔" : "✘") \(f.name)")
            print("   esito \(d.grade.rawValue) · punteggio \(Int((d.overallScore * 100).rounded()))/100"
                + " · SOH \(String(format: "%.1f", d.capacityPercent))%")
            if !ok {
                if f.bestAllowed != f.worstAllowed {
                    print("   ATTESO un esito fra \(f.bestAllowed.rawValue) e \(f.worstAllowed.rawValue)")
                } else {
                    print("   ATTESO l'esito \(f.bestAllowed.rawValue)")
                }
                if let needle = f.expectFinding {
                    print("   DEVE ESSERE SEGNALATO: \(needle)")
                }
            }
        }

        print(String(repeating: "─", count: 78))
        print(failures == 0
            ? "Tutti i \(fixtures.count) casi producono l'esito atteso."
            : "\(failures)/\(fixtures.count) casi fuori attesa.")
        return failures
    }
}
