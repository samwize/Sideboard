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
        insertCopy(of: entry)
    }

    func addReplaced(content: String, sourceApp: String?, appliedRules: [String], originalContent: String) {
        insertAtTop(ClipboardEntry(
            content: content,
            sourceApp: sourceApp,
            appliedRules: appliedRules,
            originalContent: originalContent
        ))
    }

    /// Re-derives the top entry from `base` after a rule change, preserving the
    /// cleaned/original pairing. Returns the text to place on the pasteboard, or
    /// nil when nothing changed.
    func reapplyTop(base: String, cleanedText: String, appliedRules: [String]) -> String? {
        guard let top = entries.first else { return nil }

        if top.isReplaced {
            if appliedRules.isEmpty {
                if entries.dropFirst().first?.content == base {
                    entries.removeFirst()
                } else {
                    replaceTop(with: ClipboardEntry(content: base, sourceApp: top.sourceApp, timestamp: top.timestamp))
                }
                return base
            }
            guard cleanedText != top.content || appliedRules != top.appliedRules else { return nil }
            replaceTop(with: ClipboardEntry(
                content: cleanedText,
                sourceApp: top.sourceApp,
                timestamp: top.timestamp,
                appliedRules: appliedRules,
                originalContent: base
            ))
            return cleanedText
        }

        guard !appliedRules.isEmpty else { return nil }
        addReplaced(content: cleanedText, sourceApp: top.sourceApp, appliedRules: appliedRules, originalContent: base)
        return cleanedText
    }

    func stash(_ entry: ClipboardEntry) {
        stashedEntries.removeAll { $0.content == entry.content }
        stashedEntries.insert(entry, at: 0)
        persistStashedEntries()
    }

    func unstash(_ entry: ClipboardEntry) {
        stashedEntries.removeAll { $0.id == entry.id }
        moveEntryToTop(entry)
        persistStashedEntries()
    }

    func deleteStash(_ entry: ClipboardEntry) {
        stashedEntries.removeAll { $0.id == entry.id }
        persistStashedEntries()
    }

    func clear() {
        entries.removeAll()
    }

    private func replaceTop(with entry: ClipboardEntry) {
        guard !entries.isEmpty else { return }
        entries[0] = entry
    }

    private func insertCopy(of entry: ClipboardEntry) {
        insertAtTop(ClipboardEntry(
            content: entry.content,
            sourceApp: entry.sourceApp,
            appliedRules: entry.appliedRules,
            originalContent: entry.originalContent
        ))
    }

    private func insertAtTop(_ entry: ClipboardEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    private func moveEntryToTop(_ entry: ClipboardEntry) {
        if let index = entries.firstIndex(where: { $0.content == entry.content }) {
            let existing = entries.remove(at: index)
            entries.insert(existing, at: 0)
            return
        }

        insertCopy(of: entry)
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
