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

    func stash(_ entry: ClipboardEntry) {
        history.stash(entry)
    }

    func unstash(_ entry: ClipboardEntry) {
        history.unstash(entry)
    }

    func deleteStash(_ entry: ClipboardEntry) {
        history.deleteStash(entry)
    }

    func prepareToOpenMainWindow() {
        setMainWindowPresented(true)
    }

    func mainWindowDidAppear() {
        setMainWindowPresented(true)
    }

    func mainWindowDidDisappear() {
        setMainWindowPresented(false)
    }

    private func setMainWindowPresented(_ isPresented: Bool) {
        NSApp.setActivationPolicy(isPresented ? .regular : .accessory)

        if isPresented {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

enum Tab: String, CaseIterable {
    case clipboard = "Clipboard"
    case stash = "Stash"
    case logs = "Logs"
    case settings = "Settings"
}

@main
struct SideboardApp: App {
    fileprivate static let mainWindowID = "main-window"

    @State private var appState = AppState()
    @State private var menuSelectedTab: Tab = .clipboard
    @State private var windowSelectedTab: Tab = .clipboard

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanelView(
                appState: appState,
                selectedTab: $menuSelectedTab,
                onOpenMainWindow: {
                    windowSelectedTab = menuSelectedTab
                }
            )
                .frame(width: 360, height: 400)
        } label: {
            Image(systemName: appState.sync.isSimulatorBooted ? "clipboard.fill" : "clipboard")
        }
        .menuBarExtraStyle(.window)

        Window("Sideboard", id: Self.mainWindowID) {
            MainWindowView(appState: appState, selectedTab: $windowSelectedTab)
                .frame(minWidth: 520, minHeight: 420)
        }
        .defaultSize(width: 720, height: 560)
    }
}

private struct MenuBarPanelView: View {
    @Environment(\.openWindow) private var openWindow

    let appState: AppState
    @Binding var selectedTab: Tab
    let onOpenMainWindow: () -> Void

    var body: some View {
        SideboardContentView(
            appState: appState,
            selectedTab: $selectedTab,
            availableTabs: [.clipboard, .stash],
            openMainWindow: openMainWindow
        )
    }

    private func openMainWindow() {
        let menuWindow = NSApp.keyWindow
        onOpenMainWindow()
        appState.prepareToOpenMainWindow()
        openWindow(id: SideboardApp.mainWindowID)
        menuWindow?.close()
    }
}

private struct MainWindowView: View {
    let appState: AppState
    @Binding var selectedTab: Tab

    var body: some View {
        SideboardContentView(
            appState: appState,
            selectedTab: $selectedTab,
            availableTabs: Tab.allCases
        )
            .onAppear {
                appState.mainWindowDidAppear()
            }
            .onDisappear {
                appState.mainWindowDidDisappear()
            }
    }
}
