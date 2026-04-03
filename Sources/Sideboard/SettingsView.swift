import SwiftUI

struct SettingsView: View {
    let appState: AppState

    var body: some View {
        List {
                Section("Simulator") {
                    HStack {
                        Image(systemName: appState.sync.isSimulatorBooted ? "iphone" : "iphone.slash")
                            .foregroundStyle(appState.sync.isSimulatorBooted ? .green : .secondary)
                        Text(appState.sync.isSimulatorBooted ? "Simulator connected" : "No simulator running")
                    }
                }

                Section("History") {
                    HStack {
                        Text("Entries")
                        Spacer()
                        Text("\(appState.history.entries.count)")
                            .foregroundStyle(.secondary)
                    }
                    Button("Clear History") {
                        appState.history.clear()
                    }
                    .disabled(appState.history.entries.isEmpty)
                }

                Section {
                    Button("Quit SideBoard") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q")
                }
        }
    }
}
