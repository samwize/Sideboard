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
    }
}

enum Tab {
    case clipboard, logs, settings
}

@main
struct SideboardApp: App {
    @State private var appState = AppState()
    @State private var selectedTab: Tab = .clipboard

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 0) {
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

                Divider()

                HStack(spacing: 0) {
                    TabBarButton(icon: "clipboard", label: "Clipboard", tab: .clipboard, selected: $selectedTab)
                    TabBarButton(icon: "doc.text", label: "Logs", tab: .logs, selected: $selectedTab)
                    TabBarButton(icon: "gear", label: "Settings", tab: .settings, selected: $selectedTab)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .frame(width: 320, height: 400)
        } label: {
            Image(systemName: appState.sync.isSimulatorBooted ? "clipboard.fill" : "clipboard")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct TabBarButton: View {
    let icon: String
    let label: String
    let tab: Tab
    @Binding var selected: Tab

    private var isSelected: Bool { selected == tab }

    var body: some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 9))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
