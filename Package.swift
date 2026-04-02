// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Sideboard",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Sideboard",
            path: "Sources/Sideboard"
        )
    ]
)
