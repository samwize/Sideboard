import SwiftUI

struct SideboardContentView: View {
    let appState: AppState
    @Binding var selectedTab: Tab
    let availableTabs: [Tab]
    var openMainWindow: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: availableSelection) {
                ForEach(availableTabs, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Group {
                switch resolvedTab {
                case .clipboard:
                    ClipboardView(
                        history: appState.history,
                        onRecopy: { entry in
                            appState.recopy(entry)
                        },
                        onStash: { entry in
                            appState.stash(entry)
                        }
                    )
                case .stash:
                    StashView(
                        history: appState.history,
                        onUnstash: { entry in
                            appState.unstash(entry)
                        },
                        onDelete: { entry in
                            appState.deleteStash(entry)
                        }
                    )
                case .logs:
                    LogView(logStore: appState.log)
                case .settings:
                    SettingsView(appState: appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let openMainWindow {
                Divider()

                HStack {
                    Spacer()

                    Button("Open Sideboard") {
                        openMainWindow()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(12)
            }
        }
    }

    private var availableSelection: Binding<Tab> {
        Binding(
            get: { resolvedTab },
            set: { selectedTab = $0 }
        )
    }

    private var resolvedTab: Tab {
        availableTabs.contains(selectedTab) ? selectedTab : availableTabs[0]
    }
}
