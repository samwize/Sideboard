import Foundation

@MainActor
@Observable
final class ClipboardHistory {
    private(set) var entries: [ClipboardEntry] = []
    var lastWrittenContent: String?

    private let maxEntries = 100

    func add(content: String, sourceApp: String?) {
        let isOurWrite = content == lastWrittenContent
        lastWrittenContent = nil
        if isOurWrite { return }
        let entry = ClipboardEntry(content: content, sourceApp: sourceApp)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    func moveToTop(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
        let fresh = ClipboardEntry(content: entry.content, sourceApp: entry.sourceApp)
        entries.insert(fresh, at: 0)
    }

    func clear() {
        entries.removeAll()
    }
}
