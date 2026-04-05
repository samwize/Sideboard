import Foundation

enum ProcessRunner {
    private static let xcrun = URL(fileURLWithPath: "/usr/bin/xcrun")

    @discardableResult
    static func simctl(_ arguments: [String], input: String? = nil) async -> String? {
        let xcrun = xcrun
        let environment = simctlEnvironment(from: ProcessInfo.processInfo.environment)

        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = xcrun
                process.arguments = ["simctl"] + arguments
                process.environment = environment

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
                let encodings: [String.Encoding]
                if data.contains(0) {
                    encodings = [.utf16LittleEndian, .utf16BigEndian, .utf16, .utf8]
                } else {
                    encodings = [.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian]
                }

                for encoding in encodings {
                    if let output = String(data: data, encoding: encoding) {
                        continuation.resume(returning: output)
                        return
                    }
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private static func simctlEnvironment(from base: [String: String]) -> [String: String] {
        var environment = base
        environment["LANG"] = "en_US.UTF-8"
        environment["LC_CTYPE"] = "en_US.UTF-8"
        environment["LC_ALL"] = "en_US.UTF-8"
        return environment
    }
}
