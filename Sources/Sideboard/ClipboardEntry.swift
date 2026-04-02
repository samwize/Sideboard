import Foundation

struct ClipboardEntry: Identifiable {
    let id = UUID()
    let content: String
    let sourceApp: String?
    let timestamp = Date()

    var preview: String {
        let lines = content.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
        let twoLines = lines.prefix(2).joined(separator: "\n")
        if twoLines.count > 200 {
            return String(twoLines.prefix(200)) + "..."
        }
        if lines.count > 2 {
            return twoLines + "..."
        }
        return twoLines
    }
}
