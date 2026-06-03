// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ios-appstore-production-kit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AppStoreProductionKit",
            targets: ["AppStoreProductionKit"]
        ),
        .executable(
            name: "ProductionKitDemo",
            targets: ["ProductionKitDemo"]
        )
    ],
    targets: [
        .target(
            name: "AppStoreProductionKit"
        ),
        .executableTarget(
            name: "ProductionKitDemo",
            dependencies: ["AppStoreProductionKit"],
            path: "Examples/ProductionKitDemo",
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "AppStoreProductionKitTests",
            dependencies: ["AppStoreProductionKit"]
        )
    ]
)
