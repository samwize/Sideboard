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

                // simctl clipboard output is usually UTF-8, but some payloads come back as UTF-16
                // with or without a BOM. Decode the obvious BOM case first, then use null-byte
                // placement as a fallback heuristic before giving up to UTF-8.
                guard !data.isEmpty else {
                    continuation.resume(returning: "")
                    return
                }

                if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
                    continuation.resume(returning: String(data: data, encoding: .utf16))
                    return
                }

                if data.contains(0) {
                    let bytes = Array(data)
                    let evenNullCount = stride(from: 0, to: bytes.count, by: 2).filter { bytes[$0] == 0 }.count
                    let oddNullCount = stride(from: 1, to: bytes.count, by: 2).filter { bytes[$0] == 0 }.count

                    let encodings: [String.Encoding]
                    if oddNullCount > evenNullCount {
                        encodings = [.utf16LittleEndian, .utf16BigEndian, .utf8]
                    } else if evenNullCount > oddNullCount {
                        encodings = [.utf16BigEndian, .utf16LittleEndian, .utf8]
                    } else {
                        encodings = [.utf16, .utf16LittleEndian, .utf16BigEndian, .utf8]
                    }

                    for encoding in encodings {
                        if let output = String(data: data, encoding: encoding) {
                            continuation.resume(returning: output)
                            return
                        }
                    }

                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: String(data: data, encoding: .utf8))
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
