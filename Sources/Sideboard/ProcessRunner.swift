import Foundation

enum ProcessRunner {
    private static let xcrun = URL(fileURLWithPath: "/usr/bin/xcrun")

    @discardableResult
    static func simctl(_ arguments: [String], input: String? = nil) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = xcrun
                process.arguments = ["simctl"] + arguments

                if let input {
                    let inputPipe = Pipe()
                    process.standardInput = inputPipe
                    inputPipe.fileHandleForWriting.write(Data(input.utf8))
                    inputPipe.fileHandleForWriting.closeFile()
                }

                let outputPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    continuation.resume(returning: String(data: data, encoding: .utf8))
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
