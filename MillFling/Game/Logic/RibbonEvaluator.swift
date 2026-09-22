import Foundation

/// Aggregate facts the evaluator needs after a run is stored.
struct FarmSnapshot {
    var fieldsSown = 0
    var sownByRegion: [RegionKey: Int] = [:]
    var threeStarByRegion: [RegionKey: Int] = [:]
    var totalStars = 0
    var totalTrueSows = 0
    var flaxPlots = 0
    var seedsUnlocked = 0
    var totalSeedsSown = 0
    var goldenSown = 0
    var dailyStreak = 0
    var dailyCompleted = 0
    var rank = 1
    var paintsUnlocked = 1
    var distinctSeedsSown = 0
    var totalRuns = 0
}

/// Pure mapping from a finished run + farm snapshot to new ribbon progress values.
enum RibbonEvaluator {
    static func progress(for key: RibbonKey, run: RunTracker?, firstAttempt: Bool,
                         snapshot s: FarmSnapshot, current: Int) -> Int {
        let won = run?.quotaMet ?? false
        switch key {
        case .firstFurrow: return min(1, s.fieldsSown)
        case .twelveSown, .fullCrate, .crownBearer: return s.fieldsSown
        case .gustrider: return max(current, (run?.gustSow ?? false) ? 1 : 0)
        case .noPodLeft:
            guard let run, won else { return current }
            return max(current, (run.stars == 3 && run.podsLeft >= 5) ? 1 : 0)
        case .crowShy:
            guard let run, won, run.field.crows > 0 else { return current }
            return max(current, run.crowLosses == 0 ? 1 : 0)
        case .terraceHand: return s.threeStarByRegion[.terraced] ?? 0
        case .meadowPerfect: return s.threeStarByRegion[.meadow] ?? 0
        case .stillWaters: return s.threeStarByRegion[.lakeside] ?? 0
        case .coastlineSower: return s.sownByRegion[.coast] ?? 0
        case .orchardKeeper: return s.sownByRegion[.orchard] ?? 0
        case .linenWeaver: return s.sownByRegion[.linen] ?? 0
        case .windwardSower:
            guard let run, won else { return current }
            return max(current, run.maxWindDuringRun > 2.0 ? 1 : 0)
        case .trueAim: return s.totalTrueSows
        case .flaxMaster: return s.flaxPlots
        case .longThrow: return max(current, (run?.farRightSow ?? false) ? 1 : 0)
        case .chainOfNine: return max(current, (run?.bestStreak ?? 0) >= 9 ? 1 : 0)
        case .stoneSkipper: return max(current, (run?.stoneSkip ?? false) ? 1 : 0)
        case .stormKeeper:
            guard let run, won, run.field.region.key == .storm, firstAttempt, !run.field.isDaily else { return current }
            return 1
        case .almanacFilled: return s.seedsUnlocked
        case .millKeeper: return s.totalSeedsSown
        case .fiftyStars, .hundredStars, .starField: return s.totalStars
        case .goldenTouch: return s.goldenSown
        case .goldRush:
            guard let run, won, run.field.goldenCount > 0 else { return current }
            return max(current, run.goldenSown >= run.field.goldenCount ? 1 : 0)
        case .sunriseSower: return min(1, s.dailyCompleted)
        case .threeSuns, .weekOfSuns, .monthOfSuns: return max(current, s.dailyStreak)
        case .almanacOfDays: return s.dailyCompleted
        case .furrowHand, .sailMaster, .millLegend: return s.rank
        case .paintedSails: return s.paintsUnlocked
        case .fullHopper: return s.distinctSeedsSown
        case .everyPodCounts:
            guard let run, won else { return current }
            return max(current, (run.emptyPods == 0 && run.podsUsed >= 3) ? 1 : 0)
        case .bigBloom: return max(current, (run?.score ?? 0) >= 10_000 ? 1 : 0)
        case .longSeason: return s.totalRuns
        }
    }
}
