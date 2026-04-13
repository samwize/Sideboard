import SwiftUI

struct ClipboardView: View {
    let history: ClipboardHistory
    let onRecopy: (ClipboardEntry) -> Void
    let onStash: (ClipboardEntry) -> Void

    var body: some View {
        if history.entries.isEmpty {
            ContentUnavailableView("No clipboard history yet", systemImage: "clipboard")
        } else {
            let entries = history.entries

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if Self.shouldShowDivider(at: index, in: entries) {
                            TimeDivider(date: entry.timestamp)
                        }
                        ClipboardEntryRow(
                            entry: entry,
                            actions: [
                                ClipboardEntryAction(
                                    systemImage: "tray.and.arrow.down.fill",
                                    help: "Stash",
                                    role: .normal
                                ) {
                                    onStash(entry)
                                },
                                ClipboardEntryAction(
                                    systemImage: "square.on.square",
                                    help: "Copy again",
                                    role: .normal
                                ) {
                                    onRecopy(entry)
                                }
                            ]
                        )
                    }
                }
            }
        }
    }

    nonisolated static func shouldShowDivider(at index: Int, in entries: [ClipboardEntry]) -> Bool {
        if index == 0 { return true }

        guard entries.indices.contains(index), entries.indices.contains(index - 1) else {
            return false
        }

        let current = entries[index]
        let previous = entries[index - 1]
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
