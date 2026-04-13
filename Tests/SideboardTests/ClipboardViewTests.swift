import Foundation
import Testing
@testable import Sideboard

struct ClipboardViewTests {
    @Test
    func firstEntryShowsDivider() {
        let entries = [
            ClipboardEntry(
                id: UUID(),
                content: "Current",
                sourceApp: nil,
                timestamp: Date()
            )
        ]

        #expect(ClipboardView.shouldShowDivider(at: 0, in: entries))
    }

    @Test
    func staleIndexDoesNotTrap() {
        let entries: [ClipboardEntry] = []

        #expect(ClipboardView.shouldShowDivider(at: 1, in: entries) == false)
    }

    @Test
    func dividerAppearsAfterFiveMinuteGap() {
        let now = Date()
        let entries = [
            ClipboardEntry(
                id: UUID(),
                content: "Latest",
                sourceApp: nil,
                timestamp: now
            ),
            ClipboardEntry(
                id: UUID(),
                content: "Older",
                sourceApp: nil,
                timestamp: now.addingTimeInterval(-301)
            )
        ]

        #expect(ClipboardView.shouldShowDivider(at: 1, in: entries))
    }
}
