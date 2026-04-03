import SwiftUI

@MainActor
@Observable
final class AppState {
    let history = ClipboardHistory()
    let log = LogStore()
    let sync: SimulatorSync

    init() {
        sync = SimulatorSync(history: history, log: log)
    }

    func recopy(_ entry: ClipboardEntry) {
        let current = NSPasteboard.general.string(forType: .string)
        guard current != entry.content else { return }
        history.lastWrittenContent = entry.content
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.content, forType: .string)
        history.moveToTop(entry)
    }
}

enum Tab: String, CaseIterable {
    case clipboard = "Clipboard"
    case logs = "Logs"
    case settings = "Settings"
}

@main
struct SideboardApp: App {
    @State private var appState = AppState()
    @State private var selectedTab: Tab = .clipboard

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Group {
                    switch selectedTab {
                    case .clipboard:
                        ClipboardView(history: appState.history) { entry in
                            appState.recopy(entry)
                        }
                    case .logs:
                        LogView(logStore: appState.log)
                    case .settings:
                        SettingsView(appState: appState)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: 320, height: 400)
        } label: {
            Image(systemName: appState.sync.isSimulatorBooted ? "clipboard.fill" : "clipboard")
        }
        .menuBarExtraStyle(.window)
    }
}
