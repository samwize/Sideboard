import Foundation

@MainActor
@Observable
final class ClipboardHistory {
    private(set) var entries: [ClipboardEntry] = []
    private(set) var stashedEntries: [ClipboardEntry] = []
    var lastWrittenContent: String?

    private let defaults = UserDefaults.standard
    private let maxEntries = 100
    private let stashKey = "stashedClipboardEntries"

    init() {
        loadStashedEntries()
    }

    func add(content: String, sourceApp: String?) {
        let isOurWrite = content == lastWrittenContent
        lastWrittenContent = nil
        if isOurWrite { return }
        insertAtTop(ClipboardEntry(content: content, sourceApp: sourceApp))
    }

    func moveToTop(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
        insertAtTop(ClipboardEntry(content: entry.content, sourceApp: entry.sourceApp))
    }

    func stash(_ entry: ClipboardEntry) {
        stashedEntries.removeAll { $0.content == entry.content }
        stashedEntries.insert(entry, at: 0)
        persistStashedEntries()
    }

    func unstash(_ entry: ClipboardEntry) {
        stashedEntries.removeAll { $0.id == entry.id }
        moveEntryToTop(content: entry.content, sourceApp: entry.sourceApp)
        persistStashedEntries()
    }

    func deleteStash(_ entry: ClipboardEntry) {
        stashedEntries.removeAll { $0.id == entry.id }
        persistStashedEntries()
    }

    func clear() {
        entries.removeAll()
    }

    private func insertAtTop(_ entry: ClipboardEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    private func moveEntryToTop(content: String, sourceApp: String?) {
        if let index = entries.firstIndex(where: { $0.content == content }) {
            let entry = entries.remove(at: index)
            entries.insert(entry, at: 0)
            return
        }

        insertAtTop(ClipboardEntry(content: content, sourceApp: sourceApp))
    }

    private func loadStashedEntries() {
        guard let data = defaults.data(forKey: stashKey),
              let entries = try? JSONDecoder().decode([ClipboardEntry].self, from: data)
        else {
            return
        }
        stashedEntries = entries
    }

    private func persistStashedEntries() {
        guard let data = try? JSONEncoder().encode(stashedEntries) else { return }
        defaults.set(data, forKey: stashKey)
    }
}
