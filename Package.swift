// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrHxWakePilot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BrHxWakePilot", targets: ["BrHxWakePilot"])
    ],
    targets: [
        .executableTarget(
            name: "BrHxWakePilot",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "BrHxWakePilotTests",
            dependencies: ["BrHxWakePilot"],
            path: "Tests"
        )
    ]
)
