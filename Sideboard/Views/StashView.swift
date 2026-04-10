import SwiftUI

struct StashView: View {
    let history: ClipboardHistory
    let onUnstash: (ClipboardEntry) -> Void
    let onDelete: (ClipboardEntry) -> Void

    var body: some View {
        if history.stashedEntries.isEmpty {
            ContentUnavailableView("No stashed items yet", systemImage: "archivebox")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(history.stashedEntries) { entry in
                        ClipboardEntryRow(
                            entry: entry,
                            actions: [
                                ClipboardEntryAction(
                                    systemImage: "arrow.uturn.backward.circle",
                                    help: "Unstash",
                                    role: .normal
                                ) {
                                    onUnstash(entry)
                                },
                                ClipboardEntryAction(
                                    systemImage: "trash",
                                    help: "Delete",
                                    role: .destructive
                                ) {
                                    onDelete(entry)
                                }
                            ]
                        )
                    }
                }
            }
        }
    }
}
