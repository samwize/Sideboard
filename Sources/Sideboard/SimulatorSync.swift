import AppKit

@MainActor
@Observable
final class SimulatorSync {
    private(set) var isSimulatorBooted = false

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var lastSimContent = ""
    private var pollCount = 0

    init() {
        lastChangeCount = pasteboard.changeCount
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
            isSimulatorBooted = output?.contains("(Booted)") ?? false
        }
        pollCount += 1

        guard isSimulatorBooted else { return }

        // Mac -> Simulator
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let content = pasteboard.string(forType: .string) {
                lastSimContent = content
                await ProcessRunner.simctl(["pbcopy", "booted"], input: content)
            }
        }

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
            }
        }
    }
}
