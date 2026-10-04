// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AutherisKit",
    platforms: [.iOS(.v15), .macOS(.v12), .visionOS(.v1)],
    products: [
        .library(name: "AutherisKit", targets: ["AutherisKit"]),
    ],
    targets: [
        .target(name: "AutherisKit"),
        .testTarget(name: "AutherisKitTests", dependencies: ["AutherisKit"]),
    ]
)
