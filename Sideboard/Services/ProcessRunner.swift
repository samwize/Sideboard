import Foundation

enum ProcessRunner {
    private static let xcrun = URL(fileURLWithPath: "/usr/bin/xcrun")

    @discardableResult
    static func simctl(_ arguments: [String], input: String? = nil) async -> String? {
        let xcrun = xcrun
        let environment = simctlEnvironment(from: ProcessInfo.processInfo.environment)

        @Sendable func decodeOutput(_ data: Data) -> String? {
            guard !data.isEmpty else { return "" }

            if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
                return String(data: data, encoding: .utf16)
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
                        return output
                    }
                }
                return nil
            }

            return String(data: data, encoding: .utf8)
        }

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
                continuation.resume(returning: decodeOutput(data))
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
