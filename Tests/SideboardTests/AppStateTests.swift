import Foundation
import Testing
@testable import Sideboard

@MainActor
struct AppStateTests {
    @Test
    func unstashCopiesEntryToPasteboard() {
        var clipboard = "Current clipboard"
        let appState = AppState(
            readPasteboard: { clipboard },
            writePasteboard: { clipboard = $0 }
        )
        let entry = ClipboardEntry(content: "Saved clipboard", sourceApp: "Notes")

        appState.unstash(entry)

        #expect(clipboard == "Saved clipboard")
        #expect(appState.history.entries.first?.content == "Saved clipboard")
    }
}
