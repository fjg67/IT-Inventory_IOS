// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Managed by VSXcode — changes will be overwritten

import PackageDescription

let package = Package(
    name: "ItInventory",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ItInventory",
            targets: ["ItInventory"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(
            name: "ItInventory",
            dependencies: [.product(name: "Supabase", package: "supabase-swift")],
            path: "ItInventory",
            resources: [
                .process("Assets.xcassets"),
                .process("LaunchScreen.storyboard")
            ],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))],
            linkerSettings: [.linkedFramework("Supabase")]
        ),
        .target(
            name: "ItInventoryTests",
            dependencies: [.target(name: "ItInventory")],
            path: "ItInventoryTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .unsafeFlags(["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib", "-enable-testing"])
            ]
        )
    ]
)
