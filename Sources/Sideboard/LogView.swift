import SwiftUI
import OSLog

struct LogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let message: String
    let level: OSLogEntryLog.Level
}

struct LogView: View {
    @State private var logEntries: [LogEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Logs")
                    .font(.headline)
                Spacer()
                Button { refreshLogs() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            .padding(12)

            Divider()

            if logEntries.isEmpty {
                ContentUnavailableView("No logs yet", systemImage: "doc.text")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logEntries) { entry in
                            LogEntryRow(entry: entry)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .onAppear { refreshLogs() }
    }

    private func refreshLogs() {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(date: Date().addingTimeInterval(-86400))
            var entries = try store.getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == "com.samwize.sideboard" }
                .map { LogEntry(date: $0.date, message: $0.composedMessage, level: $0.level) }
            entries.reverse()
            logEntries = entries
        } catch {}
    }
}

private struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: levelIcon)
                .font(.caption2)
                .foregroundStyle(levelColor)
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                Text(entry.date.formatted(date: .omitted, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var levelIcon: String {
        switch entry.level {
        case .error: "exclamationmark.circle.fill"
        case .fault: "xmark.circle.fill"
        case .debug: "ant"
        default: "info.circle"
        }
    }

    private var levelColor: Color {
        switch entry.level {
        case .error, .fault: .red
        case .debug: .gray
        default: .blue
        }
    }
}
