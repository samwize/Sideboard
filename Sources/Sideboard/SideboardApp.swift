import SwiftUI

@main
struct SideboardApp: App {
    @State private var sync = SimulatorSync()

    var body: some Scene {
        MenuBarExtra {
            if sync.isSimulatorBooted {
                Text("Syncing to Simulator")
            } else {
                Text("No Simulator running")
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: sync.isSimulatorBooted ? "clipboard.fill" : "clipboard")
        }
    }
}
