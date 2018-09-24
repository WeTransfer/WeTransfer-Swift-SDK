// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "WeTransfer-Swift-SDK",
	products: [
		.library(name: "WeTransfer", targets: ["WeTransfer"])
	],
	targets: [
		.target(name: "WeTransfer", path: "WeTransfer"),
		.testTarget(
			name: "WeTransfer Tests",
			dependencies: ["WeTransfer"],
			path: "WeTransferTests")
	]
)
