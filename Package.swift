// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "Corewise",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "Corewise", targets: ["Corewise"])
  ],
  targets: [
    .executableTarget(
      name: "Corewise",
      path: "Sources/Corewise",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "CorewiseTests",
      dependencies: ["Corewise"]
    )
  ]
)
