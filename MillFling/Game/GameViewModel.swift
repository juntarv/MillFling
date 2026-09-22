import SwiftUI
import SpriteKit

struct HUDState: Equatable {
    var score = 0
    var plotsSown = 0
    var quota = 1
    var podsLeft = 0
    var podsTotal = 0
    var streak = 0
    var wind = 0.0
    var showHint = false
    var hintText = ""
    var fieldNumber = 1
    var regionName = ""
    var title = "Field 1"
    var goldenLeft = 0
}

struct HarvestReport: Equatable {
    enum Outcome { case sown, fallow }
    var outcome: Outcome
    var fieldIndex: Int
    var fieldNumber: Int
    var regionName: String
    var score: Int
    var stars: Int
    var isNewBest: Bool
    var plotsSown: Int
    var quota: Int
    var podsLeft: Int
    var podsTotal: Int
    var bestStreak: Int
    var seedsLanded: Int
    var seedName: String
    var earnedRibbons: [String]
    var unlockedSeeds: [String]
    var nextFieldUnlocked: Bool
    var gateMessage: String?
    var isDaily: Bool = false
    var dailyLabel: String = ""
    var dailyStreak: Int = 0
    var firstDailyToday: Bool = false
    var bushels: Int = 0
    var rankLevel: Int = 1
    var rankTitle: String = ""
    var rankedUp: Bool = false
    var rankProgress: Double = 0
    var nextRankTitle: String?
    var unlockedPaints: [String] = []
    var regionCleared: String?
    var goldenSown: Int = 0
    var goldenTotal: Int = 0
}

/// Bridges the one GameScene and SwiftUI. Owns the run's state machine and persists results.
final class GameViewModel: ObservableObject, GameSceneEvents {
    @Published private(set) var state: GameState = .ready
    @Published private(set) var hud = HUDState()
    @Published private(set) var report: HarvestReport?
    @Published private(set) var isDemo = false

    /// Created exactly once for the lifetime of the app.
    let scene: GameScene
    private(set) var field: FieldDefinition = FieldCatalog.field(0)
    private var tracker: RunTracker
    private weak var store: FarmStore?
    private var runStart = Date()
    private var animationsOn = true

    init() {
        scene = GameScene(size: CGSize(width: 390, height: 844))
        tracker = RunTracker(field: FieldCatalog.field(0), seed: SeedCatalog.variety(nil))
        scene.events = self
    }

    func attach(store: FarmStore) {
        self.store = store
    }

    // MARK: state machine — the only place `state` changes

    private func transition(to next: GameState) {
        guard state.canMove(to: next) else { return }
        state = next
        scene.setRunning(next == .playing)
        scene.isPaused = next != .playing
    }

    // MARK: intents

    func start(fieldIndex: Int) {
        let demo = LaunchOptions.demoMode
        begin(field: demo ? FieldCatalog.demo : FieldCatalog.field(fieldIndex), demo: demo)
    }

    func startDemo() {
        begin(field: FieldCatalog.demo, demo: true)
    }

    /// Today's Daily Sowing field (or a given day's, for replays of the calendar).
    func startDaily(dayKey: String) {
        begin(field: FieldCatalog.daily(dayKey: dayKey), demo: false)
    }

    private func begin(field def: FieldDefinition, demo: Bool) {
        transition(to: .ready)
        field = def
        isDemo = demo
        report = nil
        let variety = demo ? SeedCatalog.variety("flax") : (store?.selectedSeed ?? SeedCatalog.variety(nil))
        animationsOn = store?.preference.animationsOn ?? true
        Haptics.shared.enabled = store?.preference.hapticsOn ?? true
        scene.effectsEnabled = animationsOn
        tracker = RunTracker(field: def, seed: variety)
        var presown: [Int] = []
        if demo {
            presown = DemoScript.presownPlots.filter { $0 < def.layout.count && def.layout[$0].isSowable }
            tracker.applyDemoPreset(plots: presown.count, score: DemoScript.presetScore, streak: DemoScript.presetStreak)
        }
        let seed: UInt64
        if LaunchOptions.deterministic || demo {
            seed = DemoScript.rngSeed
        } else if let key = def.dailyKey {
            seed = DailyRules.seed(for: key)
        } else {
            seed = UInt64(max(0, def.index) * 7_919 + Int(Date().timeIntervalSince1970) % 10_000)
        }
        scene.configure(field: def, variety: variety, demo: demo ? DemoScript.throwsList : [],
                        rngSeed: seed, presown: presown)
        scene.setPaint(hex: store?.selectedPaint.hex ?? PaintCatalog.all[0].hex)
        runStart = Date()
        publishHUD(animated: false)
        hud.showHint = !demo && def.tip != nil
        hud.hintText = def.tip ?? ""
        transition(to: .playing)
    }

    func pause() {
        guard state == .playing else { return }
        Haptics.shared.tap()
        transition(to: .paused)
    }

    func resume() {
        guard state == .paused else { return }
        transition(to: .playing)
    }

    func restart() {
        begin(field: field, demo: isDemo)
    }

    /// Leaves the run without recording it.
    func leave() {
        scene.halt()
        transition(to: .ready)
        scene.setRunning(false)
        scene.isPaused = true
    }

    func updateInsets(top: CGFloat, bottom: CGFloat) {
        scene.setSafeInsets(top: top, bottom: bottom)
    }

    /// The HUD's measured height below the top safe inset — the scene keeps the mill clear of it.
    func updateHUDReserve(_ height: CGFloat) {
        scene.setHUDReserve(height)
    }

    func setHaptics(_ on: Bool) {
        store?.setHaptics(on)
    }

    // MARK: HUD

    private func publishHUD(animated: Bool) {
        var next = hud
        next.score = tracker.score
        next.plotsSown = tracker.plotsSown
        next.quota = field.quota
        next.podsLeft = tracker.podsLeft
        next.podsTotal = tracker.totalPods
        next.streak = tracker.streak
        next.wind = scene.windValue
        next.fieldNumber = field.number
        next.regionName = field.isDaily ? DailyRules.shortLabel(field.dailyKey ?? "") : field.region.name
        next.title = field.isDaily ? "Daily Sowing" : "Field \(field.number)"
        next.goldenLeft = max(0, field.goldenCount - tracker.goldenSown)
        guard next != hud else { return }
        if animated && animationsOn {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { hud = next }
        } else {
            hud = next
        }
    }

    // MARK: GameSceneEvents

    func sceneShouldReload() -> Bool {
        guard state == .playing else { return false }
        if tracker.podsLeft > 0 && !tracker.quotaMet { return true }
        if isDemo {
            // the scripted demo field loops forever for recordings
            DispatchQueue.main.async { [weak self] in self?.restart() }
        }
        return false
    }

    func sceneDidRelease() {
        tracker.podReleased()
        Haptics.shared.release()
        publishHUD(animated: true)
    }

    func sceneDidBurst(seeds: Int, second: Bool) {
        if second { tracker.useSecondBurst() }
        if hud.showHint && field.index > 0 { hud.showHint = false }
        Haptics.shared.burst()
    }

    func sceneCanSecondBurst() -> Bool {
        tracker.seed.trait == .secondBurst && !tracker.secondBurstUsed
    }

    func sceneSowed(row: Int, col: Int, trueSow: Bool, pastStone: Bool, farRight: Bool, golden: Bool) {
        tracker.plotSown(trueSow: trueSow, wind: scene.windValue, farRight: farRight, pastStone: pastStone, golden: golden)
        if golden { Haptics.shared.burst() } else { Haptics.shared.sow() }
        if hud.showHint { hud.showHint = false }
        publishHUD(animated: true)
    }

    func sceneSeedResown() {
        tracker.seedLandedOnSownPlot()
    }

    func sceneSeedLost(_ reason: LossReason) {
        tracker.seedLost(toCrow: reason == .crow)
        if reason == .crow || reason == .cart { Haptics.shared.loss() }
    }

    func sceneThrowResolved() {
        let scored = tracker.podResolved()
        if !scored {
            scene.shake()
            Haptics.shared.loss()
        }
        publishHUD(animated: true)
        evaluateEnd()
    }

    func sceneWindChanged(_ wind: Double) {
        tracker.noteWind(wind)
        publishHUD(animated: true)
    }

    // MARK: end of run

    private func evaluateEnd() {
        guard state == .playing, !isDemo else { return }
        if tracker.quotaMet {
            finish(outcome: .sown)
        } else if tracker.podsLeft == 0 {
            finish(outcome: .fallow)
        }
    }

    private func finish(outcome: HarvestReport.Outcome) {
        scene.halt()
        tracker.finish()
        publishHUD(animated: true)
        let duration = Date().timeIntervalSince(runStart)
        let recorded = store?.recordRun(tracker, duration: duration)
        var next = HarvestReport(
            outcome: outcome, fieldIndex: field.index, fieldNumber: field.number,
            regionName: field.isDaily ? "Daily Sowing" : field.region.name,
            score: tracker.score, stars: recorded?.stars ?? tracker.stars, isNewBest: recorded?.isNewBest ?? false,
            plotsSown: tracker.plotsSown, quota: field.quota, podsLeft: tracker.podsLeft, podsTotal: tracker.totalPods,
            bestStreak: tracker.bestStreak, seedsLanded: tracker.seedsLanded, seedName: tracker.seed.name,
            earnedRibbons: recorded?.earnedRibbons ?? [], unlockedSeeds: recorded?.unlockedSeeds ?? [],
            nextFieldUnlocked: recorded?.nextFieldUnlocked ?? false, gateMessage: recorded?.gateMessage)
        next.isDaily = field.isDaily
        next.dailyLabel = DailyRules.longLabel(field.dailyKey ?? "")
        next.goldenSown = tracker.goldenSown
        next.goldenTotal = field.goldenCount
        if let recorded {
            next.dailyStreak = recorded.dailyStreak
            next.firstDailyToday = recorded.firstDailyToday
            next.bushels = recorded.bushels
            next.rankLevel = recorded.rankAfter.level
            next.rankTitle = recorded.rankAfter.title
            next.rankedUp = recorded.rankAfter.level > recorded.rankBefore.level
            next.rankProgress = recorded.rankProgress
            next.nextRankTitle = RankCatalog.next(after: recorded.rankAfter)?.title
            next.unlockedPaints = recorded.unlockedPaints
            next.regionCleared = recorded.regionCleared
        }
        report = next
        if outcome == .sown { Haptics.shared.success() } else { Haptics.shared.failure() }
        transition(to: outcome == .sown ? .sown : .fallow)
    }
}
