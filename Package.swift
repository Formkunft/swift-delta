// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "swift-delta",
	products: [
		.library(
			name: "DeltaModule",
			targets: ["DeltaModule"]),
	],
	targets: [
		.target(
			name: "DeltaModule"),
		.testTarget(
			name: "DeltaTests",
			dependencies: ["DeltaModule"]),
	]
)
