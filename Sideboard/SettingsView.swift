import SwiftUI

struct SettingsView: View {
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SettingsSection("Simulator") {
                    HStack(spacing: 8) {
                        Image(systemName: appState.sync.isSimulatorBooted ? "iphone" : "iphone.slash")
                            .foregroundStyle(appState.sync.isSimulatorBooted ? .green : .secondary)
                            .frame(width: 20)
                        Text(appState.sync.isSimulatorBooted ? "Connected" : "Not running")
                        Spacer()
                        Circle()
                            .fill(appState.sync.isSimulatorBooted ? .green : .red.opacity(0.6))
                            .frame(width: 8, height: 8)
                    }
                    .settingsRow()
                }

                SettingsSection("Clipboard") {
                    HStack {
                        Text("Entries")
                        Spacer()
                        Text("\(appState.history.entries.count)")
                            .foregroundStyle(.secondary)
                    }
                    .settingsRow()

                    Divider().padding(.horizontal, 12)

                    Button {
                        appState.history.clear()
                    } label: {
                        HStack {
                            Text("Clear History")
                                .foregroundStyle(appState.history.entries.isEmpty ? Color.gray : Color.red)
                            Spacer()
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(appState.history.entries.isEmpty ? Color.gray : Color.red)
                        }
                        .settingsRow()
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.history.entries.isEmpty)
                }

                SettingsSection("App") {
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack {
                            Text("Quit Sideboard")
                            Spacer()
                            Text("⌘Q")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .settingsRow()
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("q")
                }

                Text("Sideboard \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .padding(.top, 16)
            }
            .padding(.top, 4)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content
            }
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 8)
        }
    }
}

private extension View {
    func settingsRow() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}
