// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "RepsCounterKit",
    platforms: [
        .iOS(.v18),
        // macOS is listed only so that `swift test` can run the pure-logic tests on the Mac.
        .macOS(.v15),
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "ExerciseAnalyzer", targets: ["ExerciseAnalyzer"]),
        .library(name: "PoseDetection", targets: ["PoseDetection"]),
        .library(name: "Backend", targets: ["Backend"]),
    ],
    dependencies: [
        // Pinned exactly; verified 2026-11-19 (latest stable 2.x, requires iOS 16+).
        .package(url: "https://github.com/supabase/supabase-swift.git", exact: "2.55.7"),
    ],
    targets: [
        .target(name: "DesignSystem"),
        .target(name: "ExerciseAnalyzer"),
        // Apple Vision body pose → ExerciseAnalyzer frames (no third-party dependencies).
        .target(name: "PoseDetection", dependencies: ["ExerciseAnalyzer"]),
        .target(
            name: "Backend",
            dependencies: [
                "ExerciseAnalyzer",
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        ),
        .testTarget(name: "ExerciseAnalyzerTests", dependencies: ["ExerciseAnalyzer"]),
        .testTarget(name: "BackendTests", dependencies: ["Backend"]),
    ],
    swiftLanguageModes: [.v6]
)
