import Foundation

struct ClipboardEntry: Codable, Identifiable {
    let id: UUID
    let content: String
    let sourceApp: String?
    let timestamp: Date
    let appliedRules: [String]
    let originalContent: String?

    var isReplaced: Bool { !appliedRules.isEmpty }

    init(
        id: UUID = UUID(),
        content: String,
        sourceApp: String?,
        timestamp: Date = Date(),
        appliedRules: [String] = [],
        originalContent: String? = nil
    ) {
        self.id = id
        self.content = content
        self.sourceApp = sourceApp
        self.timestamp = timestamp
        self.appliedRules = appliedRules
        self.originalContent = originalContent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        appliedRules = try container.decodeIfPresent([String].self, forKey: .appliedRules) ?? []
        originalContent = try container.decodeIfPresent(String.self, forKey: .originalContent)
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
