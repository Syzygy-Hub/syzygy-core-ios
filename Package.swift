// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SyzygyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SyzygyCore", targets: ["SyzygyCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/Syzygy-Hub/syzygy-foundation-ios", exact: "1.1.0")
    ],
    targets: [
        .target(
            name: "SyzygyCore",
            dependencies: [
                .product(name: "SyzygyFoundation", package: "syzygy-foundation-ios")
            ],
            path: "Sources/SyzygyCore"
        ),
        .testTarget(
            name: "SyzygyCoreTests",
            dependencies: ["SyzygyCore"],
            path: "Tests/SyzygyCoreTests"
        )
    ]
)
