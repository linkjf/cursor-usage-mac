// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CursorUsageMenubar",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "CursorUsageMenubar", targets: ["CursorUsageMenubar"])
  ],
  targets: [
    .executableTarget(
      name: "CursorUsageMenubar",
      path: "Sources/CursorUsageMenubar",
      resources: [.process("Resources")],
      linkerSettings: [.linkedLibrary("sqlite3")]
    ),
    .testTarget(
      name: "CursorUsageMenubarTests",
      dependencies: ["CursorUsageMenubar"],
      path: "Tests/CursorUsageMenubarTests"
    ),
  ]
)
