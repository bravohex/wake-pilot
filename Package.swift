// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StayActive",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "StayActive", targets: ["StayActive"])
    ],
    targets: [
        .executableTarget(
            name: "StayActive",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "StayActiveTests",
            dependencies: ["StayActive"]
        )
    ]
)
