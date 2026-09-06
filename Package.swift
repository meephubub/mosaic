// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Mosaic",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MosaicKit", targets: ["MosaicKit"]),
        .executable(name: "Mosaic", targets: ["MosaicMain"])
    ],
    targets: [
        .target(name: "MosaicKit", path: "Sources/MosaicKit"),
        .executableTarget(
            name: "MosaicMain",
            dependencies: ["MosaicKit"],
            path: "Sources/MosaicMain"
        ),
        .executableTarget(
            name: "MosaicAppMain",
            dependencies: ["MosaicKit"],
            path: "Sources/MosaicAppMain"
        ),
        .testTarget(
            name: "MosaicKitTests",
            dependencies: ["MosaicKit"],
            path: "Tests/MosaicKitTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
