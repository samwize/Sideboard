import SwiftUI

@MainActor
@Observable
final class AppState {
    let history = ClipboardHistory()
    let sync: SimulatorSync

    init() {
        sync = SimulatorSync(history: history)
    }

    func recopy(_ entry: ClipboardEntry) {
        history.lastWrittenContent = entry.content
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.content, forType: .string)
    }
}

@main
struct SideboardApp: App {
    @State private var appState = AppState()
    @State private var showingLogs = false

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 0) {
                if showingLogs {
                    LogView()
                } else {
                    HistoryView(history: appState.history) { entry in
                        appState.recopy(entry)
                    }
                }

                Divider()

                HStack {
                    Image(systemName: appState.sync.isSimulatorBooted ? "iphone" : "iphone.slash")
                        .foregroundStyle(appState.sync.isSimulatorBooted ? .green : .secondary)
                        .font(.caption)

                    Spacer()

                    Button(showingLogs ? "History" : "Logs") {
                        showingLogs.toggle()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .keyboardShortcut("q")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(width: 320, height: 400)
        } label: {
            Image(systemName: appState.sync.isSimulatorBooted ? "clipboard.fill" : "clipboard")
        }
        .menuBarExtraStyle(.window)
    }
}
