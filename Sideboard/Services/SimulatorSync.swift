import AppKit

@MainActor
@Observable
final class SimulatorSync {
    private struct BootedSimulator: Decodable, Hashable {
        let udid: String
        let name: String
    }

    private struct BootedSimulatorList: Decodable {
        let devices: [String: [BootedSimulator]]
    }

    private(set) var isSimulatorBooted = false

    private let pasteboard = NSPasteboard.general
    private let history: ClipboardHistory
    private let log: LogStore
    private var lastChangeCount: Int
    private var bootedSimulators: [BootedSimulator] = []
    private var lastSentToSimulator: [String: String] = [:]
    private var lastObservedSimulatorContent: [String: String] = [:]
    private var pollCount = 0

    init(history: ClipboardHistory, log: LogStore) {
        self.history = history
        self.log = log
        lastChangeCount = pasteboard.changeCount
        log.info("Sideboard started")
        Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func pollOnce() async {
        if pollCount % 5 == 0 {
            await refreshBootedSimulators()
        }
        pollCount += 1

        // Mac -> Simulator (and history tracking)
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let content = pasteboard.string(forType: .string) {
                let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
                history.add(content: content, sourceApp: sourceApp)

                if isSimulatorBooted {
                    await writeToSimulators(bootedSimulators, content: content)
                    log.info("Mac → Sim (\(bootedSimulators.count)): \(content.prefix(80))")
                }
            }
        }

        guard isSimulatorBooted else { return }

        // Simulator -> Mac
        var macContent = pasteboard.string(forType: .string) ?? ""
        var pendingMacUpdate: (BootedSimulator, String)?

        for simulator in bootedSimulators {
            guard let simContent = await ProcessRunner.simctl(["pbpaste", simulator.udid]),
                  !simContent.isEmpty
            else { continue }

            if simContent == lastSentToSimulator[simulator.udid] {
                lastSentToSimulator.removeValue(forKey: simulator.udid)
                lastObservedSimulatorContent[simulator.udid] = simContent
                continue
            }

            guard simContent != lastObservedSimulatorContent[simulator.udid] else { continue }

            lastSentToSimulator.removeValue(forKey: simulator.udid)
            lastObservedSimulatorContent[simulator.udid] = simContent

            if simContent != macContent {
                pendingMacUpdate = (simulator, simContent)
                macContent = simContent
            }
        }

        if let (simulator, simContent) = pendingMacUpdate {
            pasteboard.clearContents()
            pasteboard.setString(simContent, forType: .string)
            lastChangeCount = pasteboard.changeCount
            history.add(content: simContent, sourceApp: "iOS Simulator")
            await writeToBootedSimulators(simContent, excluding: simulator.udid)
            log.info("Sim → Mac (\(simulator.name)): \(simContent.prefix(80))")
        }
    }

    private func writeToBootedSimulators(_ content: String, excluding excludedUDID: String? = nil) async {
        let simulators = bootedSimulators.filter { $0.udid != excludedUDID }
        await writeToSimulators(simulators, content: content)
    }

    private func writeToSimulators(_ simulators: [BootedSimulator], content: String) async {
        for simulator in simulators {
            lastSentToSimulator[simulator.udid] = content
            await ProcessRunner.simctl(["pbcopy", simulator.udid], input: content)
        }
    }

    private func refreshBootedSimulators() async {
        let previousSimulators = bootedSimulators
        let previousIDs = Set(previousSimulators.map(\.udid))
        let simulators = await fetchBootedSimulators()
        let currentIDs = Set(simulators.map(\.udid))

        bootedSimulators = simulators
        isSimulatorBooted = !simulators.isEmpty

        if currentIDs.isEmpty {
            if !previousIDs.isEmpty {
                log.info("Simulator lost")
            }
            lastSentToSimulator.removeAll()
            lastObservedSimulatorContent.removeAll()
            return
        }

        for lostID in previousIDs.subtracting(currentIDs) {
            lastSentToSimulator.removeValue(forKey: lostID)
            lastObservedSimulatorContent.removeValue(forKey: lostID)
        }

        let newlyBooted = simulators.filter { !previousIDs.contains($0.udid) }
        guard !newlyBooted.isEmpty else { return }

        let macContent = pasteboard.string(forType: .string) ?? ""
        for simulator in newlyBooted {
            lastObservedSimulatorContent[simulator.udid] = macContent
        }
        if !macContent.isEmpty {
            await writeToSimulators(newlyBooted, content: macContent)
        }

        let names = newlyBooted.map(\.name).joined(separator: ", ")
        log.info("Simulator booted: \(names)")
    }

    private func fetchBootedSimulators() async -> [BootedSimulator] {
        guard let output = await ProcessRunner.simctl(["list", "devices", "booted", "--json"]),
              let data = output.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(BootedSimulatorList.self, from: data)
        else {
            return []
        }

        return decoded.devices.values
            .flatMap { $0 }
            .sorted { lhs, rhs in
                if lhs.name == rhs.name {
                    return lhs.udid < rhs.udid
                }
                return lhs.name < rhs.name
            }
    }
}
