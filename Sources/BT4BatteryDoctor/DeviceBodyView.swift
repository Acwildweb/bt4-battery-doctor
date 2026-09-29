import SwiftUI

/// Ricostruzione fedele del circuito stampato verde (PCB) del tester BT4-1CHN,
/// esattamente come appare nella scheda reale:
/// - In alto: i 2 resistori ceramici di scarica bianchi "10W 8ΩJ" con serigrafia "60-80℃ 注意高温 HOT"
/// - Al centro: cornice bianca del display LCD TFT a colori da 1,77"
/// - In basso: porta USB Type-C DC5V e i 3 pulsanti tattili a montaggio superficiale (ON/OFF/菜单, 调整, 启停/运行)
struct DeviceBodyView: View {
    let session: TestSession
    let status: DeviceStatus
    let isPoweredOn: Bool

    var body: some View {
        VStack(spacing: 10) {
            // 1. Resistenze ceramiche di scarica (10W 8ΩJ)
            cementResistorsBlock

            // 2. Serigrafia di avviso calore
            Text("60-80℃  注意高温 HOT")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.70, green: 0.88, blue: 0.70))

            // 3. Display da 1,77" con cornice bianca come la scheda fisica
            DeviceScreenView(session: session, status: status, isPoweredOn: isPoweredOn)
                .padding(3)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)

            // 4. Sezione inferiore: Porta USB-C e i 3 tasti SMD
            bottomControlsBlock
        }
        .padding(14)
        .frame(width: 288)
        .background(pcbBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(red: 0.15, green: 0.45, blue: 0.25), lineWidth: 1.5)
        )
        .softShadow(0.5, 20, y: 10)
    }

    // MARK: - Resistenze di scarica

    private var cementResistorsBlock: some View {
        VStack(spacing: 4) {
            cementResistorUnit
            cementResistorUnit
        }
    }

    private var cementResistorUnit: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color(white: 0.96), Color(white: 0.88)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: 22)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.15), lineWidth: 0.5))

            Text("10W 8ΩJ")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.45))
                .kerning(1.2)
        }
    }

    // MARK: - Fondo PCB verde

    private var pcbBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.32, blue: 0.18),
                Color(red: 0.05, green: 0.24, blue: 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Tasti fisici SMD e serigrafie

    private var bottomControlsBlock: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Porta Type-C
            VStack(spacing: 2) {
                Text("DC5V")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(white: 0.85))
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(white: 0.80), Color(white: 0.45)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 22, height: 10)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.4), lineWidth: 0.5))
            }

            Spacer(minLength: 0)

            // I tre pulsanti tattili con le serigrafie originali
            smdButton(title: "ON/OFF/菜单", subtitle: "MENU")
            smdButton(title: "调整", subtitle: "ADJUST")
            smdButton(title: "启停/运行", subtitle: "RUN/STOP")
        }
        .padding(.horizontal, 4)
    }

    private func smdButton(title: String, subtitle: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(Color(white: 0.85))

            // Corpo tasto SMD argentato con pulsantino nero centrale
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.65)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 24, height: 16)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.3), lineWidth: 0.5))

                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 8, height: 8)
            }

            Text(subtitle)
                .font(.system(size: 5.5, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: 0.70, green: 0.88, blue: 0.70))
        }
    }
}
