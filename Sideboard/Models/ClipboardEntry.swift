import Foundation

struct ClipboardEntry: Codable, Identifiable {
    let id: UUID
    let content: String
    let sourceApp: String?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        content: String,
        sourceApp: String?,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.sourceApp = sourceApp
        self.timestamp = timestamp
    }

    var preview: String {
        let lines = content.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
        let twoLines = lines.prefix(2).joined(separator: "\n")
        if twoLines.count > 200 {
            return String(twoLines.prefix(200)) + "..."
        } else if lines.count > 2 {
            return twoLines + "..."
        } else {
            return twoLines
        }
    }
}
