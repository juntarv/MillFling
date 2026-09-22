import Foundation

/// Everything that happened in one run, accumulated from scene events. Pure value type.
struct RunTracker: Equatable {
    let field: FieldDefinition
    let seed: SeedVariety

    private(set) var score = 0
    private(set) var plotsSown = 0
    private(set) var podsLeft: Int
    private(set) var podsUsed = 0
    private(set) var streak = 0              // consecutive scoring pods
    private(set) var bestStreak = 0
    private(set) var trueSows = 0
    private(set) var seedsLanded = 0
    private(set) var seedsLost = 0
    private(set) var crowLosses = 0
    private(set) var gustSow = false          // sowed while |wind| >= 3.0
    private(set) var farRightSow = false
    private(set) var stoneSkip = false
    private(set) var maxWindDuringRun = 0.0
    private(set) var completionBonus = 0
    private(set) var secondBurstUsed = false
    private(set) var goldenSown = 0
    /// Pods that resolved without sowing anything.
    private(set) var emptyPods = 0
    private(set) var luckyUsed = false

    /// Plots sown by the pod currently in the air.
    private var sownByCurrentPod = 0

    init(field: FieldDefinition, seed: SeedVariety) {
        self.field = field
        self.seed = seed
        self.podsLeft = field.pods + (seed.trait == .extraPod ? 1 : 0)
    }

    var totalPods: Int { field.pods + (seed.trait == .extraPod ? 1 : 0) }
    var quotaMet: Bool { plotsSown >= field.quota }
    var displayMultiplier: Double { ScoreRules.multiplier(streak: streak) }

    mutating func podReleased() {
        guard podsLeft > 0 else { return }
        podsLeft -= 1
        podsUsed += 1
        sownByCurrentPod = 0
    }

    mutating func useSecondBurst() { secondBurstUsed = true }

    /// Returns the points gained.
    @discardableResult
    mutating func plotSown(trueSow: Bool, wind: Double, farRight: Bool, pastStone: Bool, golden: Bool = false) -> Int {
        let gained = ScoreRules.plotScore(streak: streak, trueSow: trueSow, bloomBonus: seed.bloomBonus,
                                          golden: golden, goldenTouch: seed.trait == .goldenTouch)
        if golden { goldenSown += 1 }
        score += gained
        plotsSown += 1
        sownByCurrentPod += 1
        seedsLanded += 1
        if trueSow { trueSows += 1 }
        if abs(wind) >= 3.0 { gustSow = true }
        if farRight { farRightSow = true }
        if pastStone { stoneSkip = true }
        return gained
    }

    mutating func seedLandedOnSownPlot() { seedsLanded += 1 }

    mutating func seedLost(toCrow: Bool) {
        seedsLost += 1
        if toCrow { crowLosses += 1 }
    }

    mutating func noteWind(_ wind: Double) { maxWindDuringRun = max(maxWindDuringRun, abs(wind)) }

    /// Closes the pod's lifecycle; returns true if it scored.
    @discardableResult
    mutating func podResolved() -> Bool {
        let scored = sownByCurrentPod > 0
        if scored {
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            emptyPods += 1
            if seed.trait == .luckyStreak && !luckyUsed && streak > 0 {
                luckyUsed = true
            } else {
                streak = 0
            }
        }
        sownByCurrentPod = 0
        return scored
    }

    /// `-demoMode` opens mid-run so the first frame already shows a lived-in field.
    mutating func applyDemoPreset(plots: Int, score: Int, streak: Int) {
        plotsSown = plots
        self.score = score
        self.streak = streak
        bestStreak = streak
        let used = min(podsLeft - 1, 4)
        podsLeft -= used
        podsUsed = used
    }

    mutating func finish() {
        guard quotaMet else { return }
        completionBonus = ScoreRules.completionBonus(podsLeft: podsLeft)
        score += completionBonus
    }

    var stars: Int { field.stars(score: score, plotsSown: plotsSown, podsLeft: podsLeft) }
}
