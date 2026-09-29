# BT4 Battery Doctor 🔋🩺
> **Applicazione macOS nativa per la diagnosi e la valutazione dello stato di salute di celle al litio (18650, 21700, 26650) tramite tester BT4-1CHN.**  
> *Native macOS app for diagnosing and assessing the health state of lithium cells (18650, 21700, 26650) using the BT4-1CHN tester.*

---

## 🇮🇹 Italiano

### Panoramica
**BT4 Battery Doctor** è un'applicazione macOS nativa (scritta in Swift e SwiftUI, compilabile come binario universale per Mac Intel e Apple Silicon) ideata per interpretare e valutare lo stato reale di salute (**State of Health - SOH**) e l'efficienza delle batterie al litio a partire dai dati rilevati dal tester hardware **BT4-1CHN**.

L'interfaccia include una replica visuale fedele del circuito stampato (PCB) e dello schermo TFT a colori da 1,77" del tester, con i valori a blocchi colorati e i riferimenti hardware reali.

### Caratteristiche
- **Replica visiva 1:1**: display TFT speculare (con timer in alto, colonna Volt/Ampere/Watt a sinistra, riquadri AUTO/STOP/LOOP/mΩ a destra e barra mAh/mWh in basso).
- **Trascrizione immediata**: inserisci i valori letti sul display a fine test (stato `STA: END`).
- **Valutazione multi-criterio ponderata**:
  - Capacità reale scaricata rispetto alla nominale (SOH).
  - Resistenza interna (IR in mΩ) confrontata con i valori tipici di riferimento per ciascun formato di cella.
  - Coerenza della durata accumulata rispetto alle formule del manuale di fabbrica:  
    $t \approx \frac{\text{Capacità (mAh)}}{1000} \times (N + N + 1) \times 1.5\,\text{h}$
- **Esportazione & Condivisione**: copia rapida del report diagnostico testuale o esportazione completa in formato CSV compatibile con Excel/Numbers.
- **Nessuna dipendenza esterna**: solo framework nativi Apple (SwiftUI, AppKit), compatibile da macOS 13 (Ventura) in poi.

### Requisiti di sistema e compilazione
Non serve Xcode completo: sono sufficienti i soli **Command Line Tools** di Apple (`xcode-select --install`).

```bash
# Clona il repository
git clone https://github.com/Acwildweb/bt4-battery-doctor.git
cd bt4-battery-doctor

# Compila il bundle universale (arm64 + x86_64)
./build.sh

# Compila e avvia immediatamente
./build.sh --run

# Esegui l'auto-verifica dei test interni
./dist/BT4\ Battery\ Doctor.app/Contents/MacOS/BT4BatteryDoctor --selftest
```

L'applicazione pronta all'uso si troverà in `dist/BT4 Battery Doctor.app`.

---

## 🇬🇧 English

### Overview
**BT4 Battery Doctor** is a native macOS application (built with Swift & SwiftUI as a universal binary for Intel and Apple Silicon Macs) designed to assess the actual **State of Health (SOH)** and performance of lithium-ion cells based on measurements taken by the **BT4-1CHN** hardware battery tester.

The user interface features a faithful 1:1 visual replica of the actual green PCB hardware and the 1.77-inch color TFT LCD display, reflecting the exact colored blocks and metrics observed on the physical device.

### Key Features
- **1:1 Visual Mirror**: Exact layout matching the physical hardware display (top timer bar, Volt/Ampere/Watt on the left column, AUTO/STOP/LOOP/mΩ status boxes on the right, and bottom mAh/mWh energy band).
- **Single-Screen Data Entry**: Enter the final readings shown when the test finishes (`STA: END`).
- **Weighted Multi-Factor Diagnosis**:
  - Delivered discharge capacity vs. nominal capacity (SOH %).
  - Internal resistance (IR in mΩ) benchmarked against healthy thresholds for each cell chemistry and form factor.
  - Runtime validation based on the official manufacturer formula:  
    $t \approx \frac{\text{Capacity (mAh)}}{1000} \times (N + N + 1) \times 1.5\,\text{h}$
- **Export & Sharing**: One-click clipboard copy of the diagnostic summary or full export to CSV (compatible with Excel/Numbers).
- **Zero External Dependencies**: Pure Apple native frameworks (SwiftUI, AppKit), compatible with macOS 13 (Ventura) or newer.

### Build & Run Instructions
Full Xcode is not required; Apple's **Command Line Tools** (`xcode-select --install`) are sufficient.

```bash
# Clone the repository
git clone https://github.com/Acwildweb/bt4-battery-doctor.git
cd bt4-battery-doctor

# Build universal release binary (.app for arm64 + x86_64)
./build.sh

# Build and launch immediately
./build.sh --run

# Run internal diagnosis engine self-test
./dist/BT4\ Battery\ Doctor.app/Contents/MacOS/BT4BatteryDoctor --selftest
```

The compiled application bundle will be created at `dist/BT4 Battery Doctor.app`.

---

## 🏢 Sviluppo & Riferimenti aziendali / Corporate Info & Attribution

Questo progetto è stato ideato e sviluppato da:

**A.c. wild s.a.s.**  
Palermo (PA), Italia  
- 🌐 Sito web: [www.acwild.it](https://www.acwild.it)  
- ✉️ Email: [info@acwild.it](mailto:info@acwild.it)

### Condizioni per Fork e Ridistribuzione / Fork & Redistribution Terms
In caso di fork, derivazione, riutilizzo o ridistribuzione del codice sorgente o del software:
- **È obbligatorio mantenere sempre intatti e visibili i crediti e i riferimenti allo sviluppatore originale (A.c. wild s.a.s.)** nella documentazione, nel file README e nelle schermate informative.
- *Any fork, redistribution, or derivative work must retain clear and intact attribution to the original author and company (**A.c. wild s.a.s. - Palermo, info@acwild.it, www.acwild.it**) in the documentation, README, and about screens.*

---

## 📄 Licenza / License
Distribuito sotto licenza open-source MIT. Vedi file `LICENSE` per i dettagli completi.
