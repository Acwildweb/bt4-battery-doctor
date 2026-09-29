# bt4-battery-doctor — istruzioni per gli agenti

App macOS nativa (SwiftUI) che valuta lo stato di una cella al litio dai valori che il
tester **BT4-1CHN** mostra sul display al termine della diagnosi automatica a 2 cicli.
Leggi `README.md` per il quadro funzionale completo.

## Costruzione e verifica (comandi esatti)

```bash
./build.sh                 # compila arm64 + x86_64, crea dist/BT4 Battery Doctor.app
./build.sh --run           # compila e avvia
swift build                # compilazione debug, veloce
swift run BT4BatteryDoctor --selftest   # auto-verifica del motore di diagnosi
```

Vincoli dell'ambiente, già verificati su questa macchina:

* è installato **solo** il Command Line Tools, **non Xcode completo**: `xcodebuild` non
  esiste e `swift build --arch ...` fallisce su `xcbuild`. La build universale si
  ottiene compilando ogni taglio con `swiftc -target ... -sdk "$SDK"` e unendoli con
  `lipo`, come fa `build.sh`. Non sostituire questo meccanismo senza motivo.
* il binario **deve restare universale**: verifica sempre con
  `lipo -info "dist/BT4 Battery Doctor.app/Contents/MacOS/BT4BatteryDoctor"`.
* `swift <script>.swift` (modalità interpretazione) si blocca su questa macchina:
  gli script di supporto vanno compilati con `swiftc` ed eseguiti come binari, come
  fa `build.sh` per `Tools/make-icon.swift`.
* `iconutil -c icns` rifiuta gli iconset generati fuori da Xcode, per questo il file
  `.icns` viene composto direttamente in `Tools/make-icon.swift` (blocchi `icp4`…`ic10`).

## Regole di modifica

1. **Non toccare la build senza motivo**: `Package.swift` dichiara un solo target
   eseguibile e `platforms: [.macOS(.v13)]`. Il target minimo è 13.0: non usare API
   introdotte dopo (per esempio `@Observable`, `onChange(of:initial:)`).
2. **Nessuna dipendenza esterna**: solo SwiftUI/AppKit/Foundation. Non introdurre
   pacchetti SwiftPM.
3. **Verifica sempre il motore**: dopo qualunque modifica a `DiagnosisEngine.swift`
   esegui `--selftest`. Se cambi una soglia, aggiorna o aggiungi il caso
   corrispondente in `SelfTest.swift`, che deve continuare a terminare con
   «Tutti i N casi producono l'esito atteso».
4. **Fedeltà al dispositivo**: le etichette del display non si rinominano. I campi
   sono, nell'ordine del manuale, tensione (V), corrente (A), potenza (W), capacità
   (mAh), energia (mWh), cronometro `hhh:mm:ss`, resistenza interna (mR), i menu
   rapidi `MODE`/`STOP`/`LOOP` e lo stato `STA` (`STOP`/`RUN`/`END`).
5. **Modifiche chirurgiche**: non riformattare file interi, non riordinare import,
   non cambiare lo stile fuori dal perimetro della richiesta.
6. **Lingua**: commenti e testi dell'interfaccia in italiano, come il resto del
   progetto.

## Dove stanno le cose

| File | Contenuto |
|------|-----------|
| `DiagnosisEngine.swift` | criteri, pesi, soglie, esiti, riepilogo testuale |
| `SelfTest.swift` | casi di verifica del motore (un fixture per comportamento) |
| `Models.swift` | letture di ciclo, sessione, menu del dispositivo, formati cella |
| `DeviceScreenView.swift` | replica del display: qui si aggiungono campi a schermo |
| `DeviceBodyView.swift` | guscio, tasti, LED, connettori |
| `SessionInputView.swift` | inserimento dei valori letti sul tester |
| `ResultView.swift` | esito, criteri, annotazioni, export |
| `AppModel.swift` | stato applicativo, comandi dei tasti, CSV |
| `Theme.swift` | palette e modificatori condivisi |

`dist/` e `.build/` sono generati: non modificarli a mano.

## Limiti noti da non aggirare inventando funzionalità

Il BT4-1CHN **non ha una porta dati**: la seconda Type-C è l'uscita di scarica
esterna (Test 2). Non esistono protocolli, SDK o software PC documentati, e il
dispositivo non conserva le misure allo spegnimento. I dati si inseriscono a mano
leggendoli dal display: non promettere né simulare una comunicazione seriale.
