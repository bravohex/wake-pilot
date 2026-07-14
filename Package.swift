// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WakePilot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WakePilot", targets: ["WakePilot"])
    ],
    targets: [
        .executableTarget(
            name: "WakePilot",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "WakePilotTests",
            dependencies: ["WakePilot"],
            path: "Tests"
        )
    ]
)
