// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "RxOperators",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "RxOperators",
            targets: ["RxOperators"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0")
        .package(url: "https://github.com/dankinsoid/VDKit.git", from: "1.0.12")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RxOperators",
            dependencies: []),
        .testTarget(
            name: "RxOperatorsTests",
            dependencies: ["RxOperators"]),
    ]
)
