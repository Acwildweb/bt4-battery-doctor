// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BT4BatteryDoctor",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BT4BatteryDoctor", targets: ["BT4BatteryDoctor"])
    ],
    targets: [
        .executableTarget(
            name: "BT4BatteryDoctor",
            path: "Sources/BT4BatteryDoctor"
        )
    ]
)
