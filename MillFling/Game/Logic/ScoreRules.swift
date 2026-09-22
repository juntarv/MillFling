import Foundation

/// All scoring numbers in one place — pure, no SpriteKit.
enum ScoreRules {
    static let plotBase = 100
    static let trueSowBase = 75
    static let leftoverPodBonus = 250
    static let goldenBonus = 250
    static let maxStreakMultiplierSteps = 12      // x1 ... x4 in quarter steps
    /// A landing counts as a "true sow" inside this normalised radius of the plot centre.
    static let trueSowRadius = 0.42

    /// Streak 0 = first scoring pod of a chain.
    static func multiplier(streak: Int) -> Double {
        1.0 + 0.25 * Double(min(max(streak, 0), maxStreakMultiplierSteps))
    }

    static func plotScore(streak: Int, trueSow: Bool, bloomBonus: Int, golden: Bool = false, goldenTouch: Bool = false) -> Int {
        let bloom = trueSow ? max(0, trueSowBase + bloomBonus) : 0
        let gold = golden ? goldenBonus * (goldenTouch ? 2 : 1) : 0
        return Int((Double(plotBase + bloom + gold) * multiplier(streak: streak)).rounded())
    }

    static func completionBonus(podsLeft: Int) -> Int { podsLeft * leftoverPodBonus }
}
