// swift-tools-version: 6.3
import PackageDescription

let package = Package(
	name: "swift-delta",
	products: [
		.library(
			name: "Delta",
			targets: ["Delta"]),
	],
	targets: [
		.target(
			name: "Delta",
			swiftSettings: [
				.strictMemorySafety(),
			]),
		.testTarget(
			name: "DeltaTests",
			dependencies: ["Delta"]),
	],
)
