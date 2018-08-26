// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swiff",
    products: [
        .executable(name: "swiff", targets: ["swiff"]),
    ],
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "swiff",
            dependencies: []
        ),
    ]
)
