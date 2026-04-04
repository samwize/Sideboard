import Foundation
import OSLog

@MainActor
@Observable
final class LogStore {
    private(set) var entries: [LogEntry] = []

    let logger = Logger(subsystem: "com.just2us.sideboard", category: "sync")

    func info(_ message: String) {
        logger.info("\(message)")
        entries.append(LogEntry(id: entries.count, date: Date(), message: message, level: .info))
    }

    func error(_ message: String) {
        logger.error("\(message)")
        entries.append(LogEntry(id: entries.count, date: Date(), message: message, level: .error))
    }
}

struct LogEntry: Identifiable, Sendable {
    let id: Int
    let date: Date
    let message: String
    let level: OSLogEntryLog.Level
}
