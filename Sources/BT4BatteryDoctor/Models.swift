import Foundation

import Foundation

// MARK: - Lettura finale a display del tester

/// I valori che il BT4-1CHN mostra a display al termine della prova.
/// Sono esattamente i campi ①②③④⑤⑥⑦ del manuale (V, A, W, mAh, mWh, hhh:mm:ss, mR).
///
/// In modalità AUTO o DSG, la scheda mostra a fine test i valori accumulati
/// durante la scarica e il tempo totale di esecuzione trascorso.
struct CycleReading: Identifiable, Equatable {
    var id = UUID()

    /// Numero del ciclo (utile se si usa il tester per più sessioni successive).
    var index: Int = 1

    /// ④ Capacità scaricata in mAh (valore definitivo di scarica fornito dal tester).
    var capacityMah: Double = 0
    /// ⑤ Energia scaricata in mWh.
    var energyMWh: Double = 0
    /// ⑥ Tempo totale di esecuzione registrato dal cronometro hhh:mm:ss → convertito in secondi.
    var durationSeconds: TimeInterval = 0
    /// ⑦ Resistenza interna misurata col metodo DC a 2 fili, in mR (milliohm). 9999 se circuito aperto.
    var internalResistanceMr: Double = 40
    /// ① Tensione a display (Volt, V). A fine test a riposo è tipicamente ~3.0 - 4.2V (o stop voltage sotto carico).
    var finalVoltage: Double = 3.00
    /// ② Corrente a display (Ampere, A).
    var averageCurrent: Double = 0.95
    /// ③ Potenza a display (Watt, W). Calcolata o inserita (V × A).
    var powerWatt: Double = 2.85

    /// Capacità stimata dal tempo di scarica puro se calcolato con corrente media:
    var capacityFromTimeMah: Double { durationSeconds / 3600.0 * averageCurrent * 1000.0 }
}

// MARK: - Stato del display del dispositivo

/// Lo stato del programma, indicato da `STA:` sul display (campo ⑨).
enum DeviceStatus: String {
    case stop = "STOP"
    case run = "RUN"
    case end = "END"

    var isActive: Bool { self == .run }
}

/// Le tre modalità del menu `MODE:` (campo ⑧).
enum TestMode: String, CaseIterable, Identifiable {
    case chg = "CHG"
    case dsg = "DSG"
    case auto = "AUTO"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chg: return "Carica (CHG)"
        case .dsg: return "Scarica (DSG)"
        case .auto: return "Automatico (AUTO)"
        }
    }
}

// MARK: - Configurazione del test sul tester

/// I parametri impostabili sui menu del dispositivo: MODE, STOP, LOOP.
struct TestSettings: Equatable {
    var mode: TestMode = .auto
    /// Tensione di fine scarica (menu STOP), standard consigliato 2.8 V (11 livelli: 2.5V - 3.5V).
    var stopVoltage: Double = 2.80
    /// Numero di cicli impostato sulla scheda (menu LOOP, 1...9). Generalmente 1 o 2.
    var loopCount: Int = 1

    /// Gli 11 livelli offerti dal menu STOP.
    static let stopLevels: [Double] = (0...10).map { 2.5 + Double($0) * 0.1 }
}

// MARK: - Sessione di diagnosi

/// L'insieme dei dati immessi dall'utente leggendo la schermata del tester BT4-1CHN
/// a fine diagnosi automatica.
struct TestSession: Equatable {
    /// Capacità nominale dichiarata dal costruttore della cella, in mAh.
    var nominalCapacityMah: Double = 3000
    /// Tipo di cella (18650, 21700, ecc.), usato per tarare le soglie di resistenza interna (mR).
    var cellType: CellType = .liIon18650
    /// Parametri del test impostati sulla scheda (MODE, STOP 2.8V, LOOP).
    var settings: TestSettings = TestSettings()

    /// La lettura finale mostrata sul display a fine test.
    var reading: CycleReading = CycleReading()

    /// Compatibilità con le viste che iterano sulle letture:
    var readings: [CycleReading] { [reading] }
    var cycles: [CycleReading] {
        get { [reading] }
        set { if let first = newValue.first { reading = first } }
    }

    /// ⑥ Tempo totale sul cronometro della scheda.
    var totalTestSeconds: TimeInterval {
        get { reading.durationSeconds }
        set { reading.durationSeconds = newValue }
    }

    /// Stima del tempo teorico di scarica pura secondo la regola del manuale:
    /// `tempo (h) = capacità (mAh) / 1000 × 1,5`.
    static func estimatedDischargeSeconds(capacityMah: Double) -> TimeInterval {
        capacityMah / 1000.0 * 1.5 * 3600.0
    }

    /// Stima della durata del test automatico (carica + scarica + ricarica) secondo la formula del manuale:
    /// `tempo (h) = capacità (mAh) / 1000 × (N + N + 1) × 1.5` dove N è il numero di cicli LOOP.
    static func estimatedAutoTestSeconds(capacityMah: Double, loopCount: Int) -> TimeInterval {
        let n = Double(max(1, loopCount))
        let factor = (n + n + 1.0) * 1.5
        return (capacityMah / 1000.0) * factor * 3600.0
    }
}

// MARK: - Tipo di cella

/// Formati di cella supportati, con la capacità tipica e le soglie di resistenza interna.
enum CellType: String, CaseIterable, Identifiable {
    case liIon18650 = "18650"
    case liIon21700 = "21700"
    case liIon26650 = "26650"
    case liPo18650 = "18650 LiPo"

    var id: String { rawValue }

    /// Capacità nominale tipica, in mAh.
    var typicalNominalMah: Double {
        switch self {
        case .liIon18650, .liPo18650: return 3000
        case .liIon21700: return 4000
        case .liIon26650: return 5000
        }
    }

    /// Etichetta estesa.
    var title: String {
        switch self {
        case .liIon18650: return "18650 Li-ion"
        case .liIon21700: return "21700 Li-ion"
        case .liIon26650: return "26650 Li-ion"
        case .liPo18650: return "18650 LiPo"
        }
    }
}
