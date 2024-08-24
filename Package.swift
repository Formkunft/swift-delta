// swift-tools-version: 5.10
import PackageDescription

let package = Package(
	name: "LightTableDelta",
	products: [
		.library(
			name: "LightTableDelta",
			targets: ["LightTableDelta"]),
	],
	targets: [
		.target(
			name: "LightTableDelta"),
		.testTarget(
			name: "LightTableDeltaTests",
			dependencies: ["LightTableDelta"]),
	]
)
