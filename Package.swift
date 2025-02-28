// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "swift-delta",
	products: [
		.library(
			name: "DeltaPackage",
			targets: ["DeltaPackage"]),
	],
	targets: [
		.target(
			name: "DeltaPackage"),
		.testTarget(
			name: "DeltaTests",
			dependencies: ["DeltaPackage"]),
	]
)
