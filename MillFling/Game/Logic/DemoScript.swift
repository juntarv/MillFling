import Foundation

/// Deterministic throws for `-demoMode` and the screenshot tour.
struct DemoThrow {
    /// Sail angle (radians, 0 = east) at which the pod is released.
    let releaseAngle: Double
    /// Seconds after release when the pod bursts.
    let burstDelay: Double
}

enum DemoScript {
    static let rngSeed: UInt64 = 42

    static let throwsList: [DemoThrow] = [
        DemoThrow(releaseAngle: 1.95, burstDelay: 0.42),
        DemoThrow(releaseAngle: 2.35, burstDelay: 0.60),
        DemoThrow(releaseAngle: 1.70, burstDelay: 0.38),
        DemoThrow(releaseAngle: 2.60, burstDelay: 0.72),
        DemoThrow(releaseAngle: 2.05, burstDelay: 0.50)
    ]

    /// Plot indices already sown when the demo field opens, so the first frame looks lived-in.
    static let presownPlots: [Int] = [0, 1, 5, 8, 10, 13, 16, 19]
    static let presetScore = 8_420
    static let presetStreak = 4
}
