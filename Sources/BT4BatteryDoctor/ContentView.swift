import SwiftUI

/// Vista radice: a sinistra il tester con il suo display LCD speculare,
/// a destra l'immissione ordinata dei valori letti a display e l'esito della diagnosi.
struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var showResult = false

    var body: some View {
        ZStack {
            // Sfondo scuro con sfumature morbide per atmosfera da banco di prova
            LinearGradient(colors: [Palette.bgTop, Palette.bgMid, Palette.bgBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            RadialGradient(colors: [Palette.accent.opacity(0.12), .clear],
                           center: UnitPoint(x: 0.20, y: 0.15), startRadius: 10, endRadius: 600)
                .ignoresSafeArea()
            RadialGradient(colors: [Palette.violet.opacity(0.10), .clear],
                           center: UnitPoint(x: 0.90, y: 0.85), startRadius: 10, endRadius: 560)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 20) {
                leftColumn
                rightColumn
            }
            .padding(20)
        }
        .frame(minWidth: 1080, minHeight: 740)
        .preferredColorScheme(.dark)
    }

    // MARK: Colonna sinistra — replica visiva del tester

    private var leftColumn: some View {
        VStack(spacing: 14) {
            DeviceBodyView(
                session: model.session,
                status: model.status,
                isPoweredOn: model.isPoweredOn
            )

            VStack(spacing: 4) {
                Text("Specchio del display LCD 1,77\" del BT4-1CHN")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Palette.textSecondary)
                Text("Riproduce esattamente la grafica e i colori a blocchi della scheda reale mentre inserisci i valori a destra.")
                    .font(.system(size: 9))
                    .foregroundColor(Palette.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 300)
    }

    // MARK: Colonna destra — dati inseriti ed esito della diagnosi

    private var rightColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SessionInputView(
                    session: $model.session,
                    onShowResult: computeResult
                )

                if showResult {
                    ResultView(
                        diagnosis: model.diagnosis,
                        onCopy: model.copyReport,
                        onExport: model.exportCSV
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    hintCard
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.28), value: showResult)
    }

    private var hintCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Palette.accent)
            Text("Trascrivi i valori mostrati sul display della scheda a fine scarica/ciclo (quando compare STA: END), quindi premi «Valuta stato batteria».")
                .font(.system(size: 11.5))
                .foregroundColor(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(radius: 12)
    }

    // MARK: Azioni

    private func computeResult() {
        model.diagnosis = DiagnosisEngine.evaluate(model.session)
        withAnimation { showResult = true }
    }
}
