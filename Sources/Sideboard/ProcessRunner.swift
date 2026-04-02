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

                var inputPipe: Pipe?
                if input != nil {
                    let pipe = Pipe()
                    process.standardInput = pipe
                    inputPipe = pipe
                }

                let outputPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: nil)
                    return
                }

                if let input {
                    inputPipe?.fileHandleForWriting.write(Data(input.utf8))
                    inputPipe?.fileHandleForWriting.closeFile()
                }

                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                continuation.resume(returning: String(data: data, encoding: .utf8))
            }
        }
    }
}
