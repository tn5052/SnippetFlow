// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnippetFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SnippetFlow", targets: ["SnippetFlow"])
    ],
    targets: [
        .executableTarget(
            name: "SnippetFlow",
            path: "Sources/SnippetFlow"
        ),
        .testTarget(
            name: "SnippetFlowTests",
            dependencies: ["SnippetFlow"],
            path: "Tests/SnippetFlowTests"
        )
    ]
)
