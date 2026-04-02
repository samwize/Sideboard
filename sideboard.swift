import AppKit
import Foundation

let pasteboard = NSPasteboard.general
var lastChangeCount = pasteboard.changeCount
var lastSimContent = ""
var weJustWrote = false

print("SideBoard - Always at your side")
print("Watching clipboard for changes (polling every 1s)...")
print("Bidirectional sync with booted iOS Simulator.")
print("Press Ctrl+C to stop.\n")

func syncToSimulator(_ content: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["simctl", "pbcopy", "booted"]
    let pipe = Pipe()
    process.standardInput = pipe
    pipe.fileHandleForWriting.write(content.data(using: .utf8)!)
    pipe.fileHandleForWriting.closeFile()
    do {
        try process.run()
        process.waitUntilExit()
        lastSimContent = content
    } catch {}
}

func readSimulatorPasteboard() -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["simctl", "pbpaste", "booted"]
    let pipe = Pipe()
    process.standardOutput = pipe
    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    } catch {
        return nil
    }
}

func syncFromSimulator(_ content: String) {
    weJustWrote = true
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
    lastChangeCount = pasteboard.changeCount
    lastSimContent = content
}

func truncated(_ s: String, to maxLength: Int = 100) -> String {
    let oneLine = s.replacingOccurrences(of: "\n", with: "\\n")
    if oneLine.count > maxLength {
        return String(oneLine.prefix(maxLength)) + "..."
    }
    return oneLine
}

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "HH:mm:ss"

signal(SIGINT) { _ in
    print("\nSideBoard stopped.")
    exit(0)
}

while true {
    // Mac -> Simulator
    if pasteboard.changeCount != lastChangeCount {
        lastChangeCount = pasteboard.changeCount
        if weJustWrote {
            weJustWrote = false
        } else if let content = pasteboard.string(forType: .string) {
            let timestamp = dateFormatter.string(from: Date())
            print("[\(timestamp)] [mac] \(truncated(content))")
            syncToSimulator(content)
        }
    }

    // Simulator -> Mac
    if let simContent = readSimulatorPasteboard(),
       !simContent.isEmpty,
       simContent != lastSimContent {
        lastSimContent = simContent
        let macContent = pasteboard.string(forType: .string) ?? ""
        if simContent != macContent {
            let timestamp = dateFormatter.string(from: Date())
            print("[\(timestamp)] [sim] \(truncated(simContent))")
            syncFromSimulator(simContent)
        }
    }

    Thread.sleep(forTimeInterval: 1.0)
}
