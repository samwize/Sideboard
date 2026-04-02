import AppKit

@MainActor
@Observable
final class SimulatorSync {
    private(set) var isSimulatorBooted = false

    private let pasteboard = NSPasteboard.general
    private let history: ClipboardHistory
    private let log: LogStore
    private var lastChangeCount: Int
    private var lastSimContent = ""
    private var pollCount = 0

    init(history: ClipboardHistory, log: LogStore) {
        self.history = history
        self.log = log
        lastChangeCount = pasteboard.changeCount
        log.info("SideBoard started")
        Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func pollOnce() async {
        if pollCount % 5 == 0 {
            let output = await ProcessRunner.simctl(["list", "devices", "booted"])
            let wasBooted = isSimulatorBooted
            isSimulatorBooted = output?.contains("(Booted)") ?? false
            if isSimulatorBooted && !wasBooted {
                lastSimContent = pasteboard.string(forType: .string) ?? ""
                if !lastSimContent.isEmpty {
                    await ProcessRunner.simctl(["pbcopy", "booted"], input: lastSimContent)
                }
                log.info("Simulator booted")
            } else if !isSimulatorBooted && wasBooted {
                log.info("Simulator lost")
            }
        }
        pollCount += 1

        // Mac -> Simulator (and history tracking)
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let content = pasteboard.string(forType: .string) {
                if content == history.lastWrittenContent {
                    history.lastWrittenContent = nil
                } else {
                    let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
                    history.add(content: content, sourceApp: sourceApp)
                }

                if isSimulatorBooted {
                    lastSimContent = content
                    await ProcessRunner.simctl(["pbcopy", "booted"], input: content)
                    log.info("Mac → Sim: \(content.prefix(80))")
                }
            }
        }

        guard isSimulatorBooted else { return }

        // Simulator -> Mac
        if let simContent = await ProcessRunner.simctl(["pbpaste", "booted"]),
           !simContent.isEmpty,
           simContent != lastSimContent
        {
            lastSimContent = simContent
            let macContent = pasteboard.string(forType: .string) ?? ""
            if simContent != macContent {
                pasteboard.clearContents()
                pasteboard.setString(simContent, forType: .string)
                lastChangeCount = pasteboard.changeCount
                history.add(content: simContent, sourceApp: "iOS Simulator")
                log.info("Sim → Mac: \(simContent.prefix(80))")
            }
        }
    }
}
