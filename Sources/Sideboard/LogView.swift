import SwiftUI
import OSLog

struct LogView: View {
    let logStore: LogStore

    var body: some View {
        VStack(spacing: 0) {
            if logStore.entries.isEmpty {
                ContentUnavailableView("No logs yet", systemImage: "doc.text")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logStore.entries.reversed()) { entry in
                            LogEntryRow(entry: entry)
                        }
                    }
                    .padding(12)
                }
            }
        }
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
