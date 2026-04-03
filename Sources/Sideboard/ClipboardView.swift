import SwiftUI

struct ClipboardView: View {
    let history: ClipboardHistory
    let onRecopy: (ClipboardEntry) -> Void

    var body: some View {
        if history.entries.isEmpty {
            ContentUnavailableView("No clipboard history yet", systemImage: "clipboard")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(history.entries.enumerated()), id: \.element.id) { index, entry in
                        if shouldShowDivider(at: index) {
                            TimeDivider(date: entry.timestamp)
                        }
                        EntryRow(entry: entry, isCurrentClipboard: entry.content == currentClipboard) {
                            onRecopy(entry)
                        }
                    }
                }
            }
        }
    }

    private var currentClipboard: String? {
        NSPasteboard.general.string(forType: .string)
    }

    private func shouldShowDivider(at index: Int) -> Bool {
        if index == 0 { return true }
        let current = history.entries[index]
        let previous = history.entries[index - 1]
        return previous.timestamp.timeIntervalSince(current.timestamp) > 300
    }
}

private struct TimeDivider: View {
    let date: Date

    var body: some View {
        HStack(spacing: 8) {
            line
            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize()
            line
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private var line: some View {
        Rectangle().frame(height: 0.5).foregroundStyle(.quaternary)
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, " + date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        }
    }
}

private struct EntryRow: View {
    let entry: ClipboardEntry
    let isCurrentClipboard: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.preview)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                if let sourceApp = entry.sourceApp {
                    Text(sourceApp)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 4)

            Image(systemName: isCurrentClipboard ? "checkmark" : "square.on.square")
                .font(.system(size: 10))
                .foregroundStyle(isCurrentClipboard ? Color.green : Color.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color.accentColor.opacity(0.1) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { onTap() }
    }
}
