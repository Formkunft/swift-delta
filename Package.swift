// swift-tools-version: 6.0
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
			name: "Delta"),
		.testTarget(
			name: "DeltaTests",
			dependencies: ["Delta"]),
	]
)
