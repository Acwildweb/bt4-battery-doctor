import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// Punto di ingresso: intercetta `--selftest` prima di avviare l'interfaccia.
@main
enum Entry {
    static func main() {
        if SelfTest.runIfNeeded() { return }
        BT4BatteryDoctorApp.main()
    }
}

struct BT4BatteryDoctorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
