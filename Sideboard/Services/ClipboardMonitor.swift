import AppKit

@MainActor
@Observable
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private let history: ClipboardHistory
    private let log: LogStore
    private let ruleStore: RuleStore
    private var lastChangeCount: Int

    init(history: ClipboardHistory, log: LogStore, ruleStore: RuleStore) {
        self.history = history
        self.log = log
        self.ruleStore = ruleStore
        lastChangeCount = pasteboard.changeCount
        log.info("Sideboard started")
        Task { [weak self] in
            while !Task.isCancelled {
                self?.pollOnce()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func pollOnce() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard let content = pasteboard.string(forType: .string) else { return }
        ingest(content)
    }

    private func ingest(_ content: String) {
        let isOurWrite = content == history.lastWrittenContent
        let sourceApp = isOurWrite ? nil : NSWorkspace.shared.frontmostApplication?.localizedName
        history.add(content: content, sourceApp: sourceApp)
        guard !isOurWrite else { return }

        let result = ClipboardTransformer.apply(rules: ruleStore.rules, to: content)
        guard !result.appliedRuleNames.isEmpty else { return }

        setPasteboard(result.text)
        history.addReplaced(
            content: result.text,
            sourceApp: sourceApp,
            appliedRules: result.appliedRuleNames,
            originalContent: content
        )
        log.info("Cleaned (\(result.appliedRuleNames.joined(separator: ", "))): \(result.text.prefix(80))")
    }

    private func setPasteboard(_ content: String) {
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
}
