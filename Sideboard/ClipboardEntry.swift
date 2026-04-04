import Foundation

struct ClipboardEntry: Identifiable {
    let id = UUID()
    let content: String
    let sourceApp: String?
    let timestamp = Date()
    let preview: String

    init(content: String, sourceApp: String?) {
        self.content = content
        self.sourceApp = sourceApp
        let lines = content.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
        let twoLines = lines.prefix(2).joined(separator: "\n")
        if twoLines.count > 200 {
            self.preview = String(twoLines.prefix(200)) + "..."
        } else if lines.count > 2 {
            self.preview = twoLines + "..."
        } else {
            self.preview = twoLines
        }
    }
}
