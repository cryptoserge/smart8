// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Smart8",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Smart8", targets: ["Smart8"])
    ],
    targets: [
        .executableTarget(
            name: "Smart8",
            path: "Sources/Smart8"
        ),
        .testTarget(
            name: "Smart8Tests",
            dependencies: ["Smart8"],
            path: "Tests/Smart8Tests"
        )
    ]
)
