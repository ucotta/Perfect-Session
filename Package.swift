import PackageDescription

let package = Package(
	name: "SessionMemory",
	targets: [],
	dependencies: {
        	.Package(url: "https://github.com/PerfectlySoft/Perfect-HTTP.git", majorVersion: 2, minor: 0)
	},
	exclude: []
)

