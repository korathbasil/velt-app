// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Velt",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "VeltApp", targets: ["VeltApp"]),
        .library(name: "Velt", targets: ["Velt"]),
    ],
    targets: [
        // C++ Rendering Backend
        .target(
            name: "ImpellerBackend",
            path: "lib/ImpellerBackend",
            sources: ["impeller_renderer.cpp"],
            publicHeadersPath: "include",
            cxxSettings: [
                .unsafeFlags(["-std=c++17"]),
                .headerSearchPath("."),
                .headerSearchPath("vendor"),
            ],
            linkerSettings: [
                .linkedLibrary("dl"),
                .linkedLibrary("GL"),
                .linkedLibrary("glfw"),
            ]
        ),

        // UI Framework Library
        .target(
            name: "Velt",
            dependencies: ["ImpellerBackend"],
            path: "lib/Velt"
        ),

        // Executable App
        .executableTarget(
            name: "VeltApp",
            dependencies: ["Velt"],
            path: "Sources"
        ),
    ]
)
