import CoreData
import SwiftUI

/// What the Harvest Report needs after a run is written.
struct RecordOutcome {
    var stars: Int
    var isNewBest: Bool
    var earnedRibbons: [String]
    var unlockedSeeds: [String]
    var unlockedPaints: [String]
    var nextFieldUnlocked: Bool
    var gateMessage: String?
    var bushels: Int
    var rankBefore: Rank
    var rankAfter: Rank
    var rankProgress: Double
    var dailyStreak: Int
    var firstDailyToday: Bool
    var regionCleared: String?
}

/// Summary of one region for the map, briefings and the Farm Book.
struct RegionSummary: Identifiable {
    let region: Region
    let sown: Int
    let stars: Int
    let threeStars: Int
    let unlocked: Bool
    var id: String { region.id }
    var complete: Bool { sown == region.fieldCount }
}

/// What the SOW sign should do right now.
enum SowTarget: Equatable {
    case field(Int)
    case gated(region: String, starsNeeded: Int)
    case allSown
}

/// Owns every Core Data read/write. Views read lists via @FetchRequest; the scene never sees this.
final class FarmStore: ObservableObject {
    let context: NSManagedObjectContext
    @Published private(set) var preference: PreferenceEntity
    @Published private(set) var stats: FarmStatsEntity
    /// Bumped after every write so views depending on derived values refresh.
    @Published private(set) var revision = 0

    init(controller: PersistenceController) {
        context = controller.container.viewContext
        preference = FarmStore.fetchOrCreatePreference(in: context)
        stats = FarmStore.fetchOrCreateStats(in: context)
        seedContentIfNeeded()
    }

    // MARK: singletons

    private static func fetchOrCreatePreference(in context: NSManagedObjectContext) -> PreferenceEntity {
        let request: NSFetchRequest<PreferenceEntity> = PreferenceEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first { return existing }
        let p = PreferenceEntity(context: context)
        p.id = UUID()
        p.createdAt = Date()
        p.hapticsOn = true
        p.animationsOn = true
        p.firstLaunchCompleted = false
        p.selectedSeedKey = SeedCatalog.defaultKey
        p.selectedPaintKey = PaintCatalog.defaultKey
        p.lastFieldIndex = 0
        try? context.save()
        return p
    }

    private static func fetchOrCreateStats(in context: NSManagedObjectContext) -> FarmStatsEntity {
        let request: NSFetchRequest<FarmStatsEntity> = FarmStatsEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first { return existing }
        let s = FarmStatsEntity(context: context)
        s.id = UUID()
        s.createdAt = Date()
        s.rank = 1
        try? context.save()
        return s
    }

    // MARK: seeding — additive, so new content never wipes progress

    func seedContentIfNeeded() {
        var fieldsAdded = false
        let existingFields = Set(fieldProgress().map { Int($0.fieldIndex) })
        for f in FieldCatalog.all where !existingFields.contains(f.index) {
            let e = FieldProgressEntity(context: context)
            e.id = UUID()
            e.createdAt = Date()
            e.fieldIndex = Int16(f.index)
            e.regionKey = f.region.key.rawValue
            e.isUnlocked = f.index == 0
            fieldsAdded = true
        }

        let seedRows = seedEntities()
        for s in SeedCatalog.all {
            let e: SeedEntity
            if let found = seedRows.first(where: { $0.key == s.key }) {
                e = found
            } else {
                e = SeedEntity(context: context)
                e.id = UUID()
                e.createdAt = Date()
                e.key = s.key
                e.isUnlocked = s.unlockField == 0
            }
            e.name = s.name
            e.lore = s.lore
            e.unlockField = Int16(s.unlockField)
            e.mass = s.mass
            e.seedsPerBurst = Int16(s.seedsPerBurst)
            e.drift = s.drift
            e.bloomBonus = Int16(s.bloomBonus)
            e.sortIndex = Int16(s.sortIndex)
        }

        var ribbonsAdded = false
        let ribbonRows = ribbonEntities()
        for (i, r) in RibbonCatalog.all.enumerated() {
            let e: RibbonEntity
            if let found = ribbonRows.first(where: { $0.key == r.key.rawValue }) {
                e = found
            } else {
                e = RibbonEntity(context: context)
                e.id = UUID()
                e.createdAt = Date()
                e.key = r.key.rawValue
                ribbonsAdded = true
            }
            e.title = r.title
            e.detail = r.detail
            e.goal = Int32(r.goal)
            e.category = r.category.rawValue
            e.sortIndex = Int16(i)
        }

        let paintRows = paintEntities()
        for p in PaintCatalog.all {
            let e: MillPaintEntity
            if let found = paintRows.first(where: { $0.key == p.key }) {
                e = found
            } else {
                e = MillPaintEntity(context: context)
                e.id = UUID()
                e.createdAt = Date()
                e.key = p.key
            }
            e.name = p.name
            e.colorHex = Int64(p.hex)
            e.unlockRank = Int16(p.unlockRank)
            e.sortIndex = Int16(p.sortIndex)
        }
        if preference.selectedPaintKey == nil { preference.selectedPaintKey = PaintCatalog.defaultKey }
        stats.rank = Int16(RankCatalog.rank(for: Int(stats.bushels)).level)
        _ = refreshPaintUnlocks()

        if fieldsAdded { refreshUnlocks(fieldProgress()) }
        if ribbonsAdded { _ = evaluateRibbons(run: nil, firstAttempt: false, fields: fieldProgress()) }
        save()
    }

    private func deleteAll(_ entity: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: entity)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        for object in (try? context.fetch(request)) ?? [] { context.delete(object) }
    }

    func save() {
        if context.hasChanges {
            do { try context.save() } catch { context.rollback() }
        }
        revision += 1
    }

    // MARK: reads

    func fieldProgress() -> [FieldProgressEntity] {
        let request: NSFetchRequest<FieldProgressEntity> = FieldProgressEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "fieldIndex", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func seedEntities() -> [SeedEntity] {
        let request: NSFetchRequest<SeedEntity> = SeedEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func ribbonEntities() -> [RibbonEntity] {
        let request: NSFetchRequest<RibbonEntity> = RibbonEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func paintEntities() -> [MillPaintEntity] {
        let request: NSFetchRequest<MillPaintEntity> = MillPaintEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func dailyEntities() -> [DailyRunEntity] {
        let request: NSFetchRequest<DailyRunEntity> = DailyRunEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dayKey", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func runs(forField index: Int, limit: Int = 5) -> [RunRecordEntity] {
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "fieldIndex == %d AND dailyKey == nil", index)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }

    /// Every ledger row, oldest first — the source for Harvest Charts.
    func allRuns() -> [RunRecordEntity] {
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Runs sown with one seed variety, newest first.
    func runs(forSeed key: String) -> [RunRecordEntity] {
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "seedKey == %@", key)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func runs(inRegion key: RegionKey) -> [RunRecordEntity] {
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "regionKey == %@ AND dailyKey == nil", key.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// A guide entry is discovered once the field it first appears on has been reached.
    func isDiscovered(_ entry: GuideEntry) -> Bool {
        entry.firstField == 0 || isUnlocked(field: entry.firstField)
    }

    func statValue(_ stat: GuideStat) -> Int? {
        switch stat {
        case .none: return nil
        case .plotsSown: return Int(stats.totalPlotsSown)
        case .goldenSown: return Int(stats.goldenSown)
        case .podsFlung: return Int(stats.totalPodsFlung)
        case .seedsSown: return Int(stats.totalSeedsSown)
        case .trueSows: return Int(stats.totalTrueSows)
        case .bestStreak: return Int(stats.bestStreak)
        case .runs: return Int(stats.totalRuns)
        }
    }

    func runs(forDay key: String) -> [RunRecordEntity] {
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "dailyKey == %@", key)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    private func dailyEntry(for key: String) -> DailyRunEntity {
        if let existing = dailyEntities().first(where: { $0.dayKey == key }) { return existing }
        let d = DailyRunEntity(context: context)
        d.id = UUID()
        d.createdAt = Date()
        d.dayKey = key
        return d
    }

    var totalStars: Int { fieldProgress().reduce(0) { $0 + Int($1.stars) } }
    var fieldsSownCount: Int { fieldProgress().filter { $0.stars > 0 }.count }
    var ribbonsEarned: Int { ribbonEntities().filter(\.isEarned).count }
    var ribbonsTotal: Int { RibbonCatalog.all.count }
    var allFieldsSown: Bool { fieldsSownCount >= FieldCatalog.count }
    var hasPlayed: Bool { stats.totalRuns > 0 }

    /// First unlocked field that has not been sown yet, else the last unlocked one.
    var currentFieldIndex: Int {
        let fields = fieldProgress()
        if let open = fields.first(where: { $0.isUnlocked && $0.stars == 0 }) { return Int(open.fieldIndex) }
        return Int(fields.last(where: \.isUnlocked)?.fieldIndex ?? 0)
    }

    var sowTarget: SowTarget {
        let fields = fieldProgress()
        if let open = fields.first(where: { $0.isUnlocked && $0.stars == 0 }) { return .field(Int(open.fieldIndex)) }
        if allFieldsSown { return .allSown }
        if let locked = fields.first(where: { !$0.isUnlocked }) {
            let region = FieldCatalog.field(Int(locked.fieldIndex)).region
            return .gated(region: region.name, starsNeeded: max(0, region.starGate - totalStars))
        }
        return .field(currentFieldIndex)
    }

    var selectedSeed: SeedVariety {
        let key = preference.selectedSeedKey
        let unlocked = seedEntities().first { $0.key == key }?.isUnlocked ?? false
        return SeedCatalog.variety(unlocked ? key : SeedCatalog.defaultKey)
    }

    var selectedPaint: MillPaint {
        let key = preference.selectedPaintKey
        let unlocked = paintEntities().first { $0.key == key }?.isUnlocked ?? false
        return PaintCatalog.paint(unlocked ? key : PaintCatalog.defaultKey)
    }

    var rank: Rank { RankCatalog.rank(for: Int(stats.bushels)) }
    var rankProgress: Double { RankCatalog.progress(bushels: Int(stats.bushels)) }

    func isUnlocked(field index: Int) -> Bool {
        fieldProgress().first { Int($0.fieldIndex) == index }?.isUnlocked ?? false
    }

    func progress(field index: Int) -> FieldProgressEntity? {
        fieldProgress().first { Int($0.fieldIndex) == index }
    }

    /// Why a locked field is closed.
    func lockReason(field index: Int) -> String {
        let def = FieldCatalog.field(index)
        let isRegionStart = def.number == def.region.fields.lowerBound
        if isRegionStart && totalStars < def.region.starGate {
            return "\(def.region.name) opens at \(def.region.starGate) stars — you have \(totalStars)."
        }
        return "Sow field \(def.number - 1) to open field \(def.number)."
    }

    func regionSummaries() -> [RegionSummary] {
        let fields = fieldProgress()
        return Region.all.map { region in
            let rows = fields.filter { $0.regionKey == region.key.rawValue }
            return RegionSummary(region: region,
                                 sown: rows.filter { $0.stars > 0 }.count,
                                 stars: rows.reduce(0) { $0 + Int($1.stars) },
                                 threeStars: rows.filter { $0.stars == 3 }.count,
                                 unlocked: rows.contains { $0.isUnlocked })
        }
    }

    // MARK: daily

    var todayKey: String { DailyRules.dayKey(for: Date()) }

    var todayCompleted: Bool {
        dailyEntities().first { $0.dayKey == todayKey }?.completed ?? false
    }

    var completedDayKeys: Set<String> {
        Set(dailyEntities().filter(\.completed).compactMap(\.dayKey))
    }

    /// Live streak: days in a row up to today (or yesterday while today is still open).
    var dailyStreak: Int { DailyRules.streak(completed: completedDayKeys, today: todayKey) }

    // MARK: preference writes

    func setHaptics(_ on: Bool) {
        preference.hapticsOn = on
        Haptics.shared.enabled = on
        save()
    }

    func setAnimations(_ on: Bool) {
        preference.animationsOn = on
        save()
    }

    func selectSeed(_ key: String) {
        preference.selectedSeedKey = key
        save()
    }

    func selectPaint(_ key: String) {
        guard paintEntities().first(where: { $0.key == key })?.isUnlocked == true else { return }
        preference.selectedPaintKey = key
        save()
    }

    func completeOnboarding() {
        preference.firstLaunchCompleted = true
        save()
    }

    // MARK: run results

    func recordRun(_ run: RunTracker, duration: Double) -> RecordOutcome {
        let fields = fieldProgress()
        let stars = run.stars
        let won = run.quotaMet
        let rankBefore = rank
        var firstAttempt = false
        var firstClear = false
        var firstDailyToday = false
        var isNewBest = false
        var regionCleared: String?
        var regionBonus = 0

        if let dayKey = run.field.dailyKey {
            let daily = dailyEntry(for: dayKey)
            firstAttempt = daily.attempts == 0
            daily.attempts += 1
            daily.seedKey = run.seed.key
            if won {
                if !daily.completed {
                    daily.completed = true
                    daily.completedAt = Date()
                    firstDailyToday = true
                }
                isNewBest = run.score > Int(daily.bestScore)
                if isNewBest { daily.bestScore = Int32(run.score) }
                daily.stars = max(daily.stars, Int16(stars))
            }
        } else if let progress = fields.first(where: { Int($0.fieldIndex) == run.field.index }) {
            firstAttempt = progress.attempts == 0
            firstClear = won && progress.stars == 0
            progress.attempts += 1
            progress.lastPlayedAt = Date()
            isNewBest = won && run.score > Int(progress.bestScore)
            if won {
                if isNewBest {
                    progress.bestScore = Int32(run.score)
                    progress.bestPodsLeft = Int16(run.podsLeft)
                }
                progress.bestStreak = max(progress.bestStreak, Int16(run.bestStreak))
                progress.bestTrueSows = max(progress.bestTrueSows, Int16(run.trueSows))
                if stars > progress.stars { progress.stars = Int16(stars) }
                if progress.completedAt == nil { progress.completedAt = Date() }
            }
            if firstClear {
                let region = run.field.region
                let regionRows = fields.filter { $0.regionKey == region.key.rawValue }
                if regionRows.allSatisfy({ $0.stars > 0 }) {
                    regionCleared = region.name
                    regionBonus = region.clearBonus
                }
            }
        }

        let bushels = ProgressionRules.bushels(won: won, stars: stars, plotsSown: run.plotsSown,
                                               goldenSown: run.goldenSown, firstClear: firstClear,
                                               daily: run.field.isDaily, firstDailyToday: firstDailyToday) + regionBonus

        let record = RunRecordEntity(context: context)
        record.id = UUID()
        record.createdAt = Date()
        record.fieldIndex = Int16(run.field.index)
        record.regionKey = run.field.region.key.rawValue
        record.dailyKey = run.field.dailyKey
        record.score = Int32(run.score)
        record.plotsSown = Int16(run.plotsSown)
        record.plotsRequired = Int16(run.field.quota)
        record.podsUsed = Int16(run.podsUsed)
        record.podsLeft = Int16(run.podsLeft)
        record.bestStreak = Int16(run.bestStreak)
        record.trueSows = Int16(run.trueSows)
        record.seedsLost = Int16(run.seedsLost)
        record.goldenSown = Int16(run.goldenSown)
        record.seedKey = run.seed.key
        record.durationSeconds = duration
        record.outcome = won ? "sown" : "fallow"
        record.starsEarned = Int16(stars)
        record.bushels = Int16(min(bushels, Int(Int16.max)))

        stats.totalRuns += 1
        if won { stats.totalWins += 1 }
        stats.totalPodsFlung += Int64(run.podsUsed)
        stats.totalSeedsSown += Int64(run.seedsLanded)
        stats.totalPlotsSown += Int64(run.plotsSown)
        stats.totalTrueSows += Int32(run.trueSows)
        stats.goldenSown += Int32(run.goldenSown)
        stats.bestStreak = max(stats.bestStreak, Int16(run.bestStreak))
        stats.lastPlayedAt = Date()
        stats.bushels += Int64(bushels)
        let rankAfter = RankCatalog.rank(for: Int(stats.bushels))
        stats.rank = Int16(rankAfter.level)

        if firstDailyToday, let key = run.field.dailyKey {
            stats.dailyCompleted += 1
            stats.lastDailyKey = key
        }
        let streak = dailyStreak
        stats.dailyStreak = Int16(streak)
        stats.bestDailyStreak = max(stats.bestDailyStreak, Int16(streak))

        if let seed = seedEntities().first(where: { $0.key == run.seed.key }) {
            seed.timesUsed += 1
            seed.plotsSown += Int32(run.plotsSown)
            if won { seed.bestScore = max(seed.bestScore, Int32(run.score)) }
        }

        refreshUnlocks(fields)
        let nextIndex = run.field.index + 1
        let nextUnlocked = !run.field.isDaily && nextIndex < fields.count && fields[nextIndex].isUnlocked
        stats.totalStars = Int16(fields.reduce(0) { $0 + Int($1.stars) })
        stats.fieldsSown = Int16(fields.filter { $0.stars > 0 }.count)
        if !run.field.isDaily {
            preference.lastFieldIndex = Int16(nextUnlocked ? nextIndex : run.field.index)
        }

        let newSeeds = refreshSeedUnlocks(fields)
        let newPaints = refreshPaintUnlocks()
        let newRibbons = evaluateRibbons(run: run, firstAttempt: firstAttempt, fields: fields)
        save()

        var gate: String?
        if won, !run.field.isDaily, !nextUnlocked, nextIndex < FieldCatalog.count {
            gate = lockReason(field: nextIndex)
        }
        return RecordOutcome(stars: stars, isNewBest: isNewBest, earnedRibbons: newRibbons,
                             unlockedSeeds: newSeeds, unlockedPaints: newPaints,
                             nextFieldUnlocked: nextUnlocked, gateMessage: gate,
                             bushels: bushels, rankBefore: rankBefore, rankAfter: rankAfter,
                             rankProgress: RankCatalog.progress(bushels: Int(stats.bushels)),
                             dailyStreak: streak, firstDailyToday: firstDailyToday,
                             regionCleared: regionCleared)
    }

    private func refreshUnlocks(_ fields: [FieldProgressEntity]) {
        let stars = fields.reduce(0) { $0 + Int($1.stars) }
        for (i, f) in fields.enumerated() {
            if i == 0 { f.isUnlocked = true; continue }
            let def = FieldCatalog.field(Int(f.fieldIndex))
            let previousSown = fields[i - 1].stars > 0
            let gateOK = def.number != def.region.fields.lowerBound || stars >= def.region.starGate
            if previousSown && gateOK { f.isUnlocked = true }
        }
    }

    private func refreshSeedUnlocks(_ fields: [FieldProgressEntity]) -> [String] {
        let highestSown = fields.filter { $0.stars > 0 }.map { Int($0.fieldIndex) + 1 }.max() ?? 0
        var names: [String] = []
        for seed in seedEntities() where !seed.isUnlocked && Int(seed.unlockField) <= highestSown {
            seed.isUnlocked = true
            names.append(seed.name ?? "")
        }
        return names
    }

    private func refreshPaintUnlocks() -> [String] {
        let level = Int(stats.rank)
        var names: [String] = []
        for paint in paintEntities() where !paint.isUnlocked && Int(paint.unlockRank) <= level {
            paint.isUnlocked = true
            paint.unlockedAt = Date()
            if paint.unlockRank > 1 { names.append(paint.name ?? "") }
        }
        return names
    }

    private func snapshot(fields: [FieldProgressEntity]) -> FarmSnapshot {
        var s = FarmSnapshot()
        for f in fields {
            guard let key = RegionKey(rawValue: f.regionKey ?? "") else { continue }
            if f.stars > 0 { s.sownByRegion[key, default: 0] += 1 }
            if f.stars == 3 { s.threeStarByRegion[key, default: 0] += 1 }
        }
        let seeds = seedEntities()
        s.fieldsSown = fields.filter { $0.stars > 0 }.count
        s.totalStars = fields.reduce(0) { $0 + Int($1.stars) }
        s.totalTrueSows = Int(stats.totalTrueSows)
        s.flaxPlots = Int(seeds.first { $0.key == "flax" }?.plotsSown ?? 0)
        s.seedsUnlocked = seeds.filter(\.isUnlocked).count
        s.totalSeedsSown = Int(stats.totalSeedsSown)
        s.goldenSown = Int(stats.goldenSown)
        s.dailyStreak = Int(stats.dailyStreak)
        s.dailyCompleted = Int(stats.dailyCompleted)
        s.rank = Int(stats.rank)
        s.paintsUnlocked = paintEntities().filter(\.isUnlocked).count
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "outcome == %@", "sown")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let wins = (try? context.fetch(request)) ?? []
        s.distinctSeedsSown = Set(wins.compactMap(\.seedKey)).count
        s.totalRuns = Int(stats.totalRuns)
        return s
    }

    private func evaluateRibbons(run: RunTracker?, firstAttempt: Bool, fields: [FieldProgressEntity]) -> [String] {
        let farm = snapshot(fields: fields)
        var earned: [String] = []
        for ribbon in ribbonEntities() {
            guard let key = RibbonKey(rawValue: ribbon.key ?? "") else { continue }
            let value = RibbonEvaluator.progress(for: key, run: run, firstAttempt: firstAttempt,
                                                 snapshot: farm, current: Int(ribbon.progress))
            ribbon.progress = Int32(min(value, Int(ribbon.goal)))
            if !ribbon.isEarned && value >= Int(ribbon.goal) {
                ribbon.isEarned = true
                ribbon.earnedAt = Date()
                earned.append(ribbon.title ?? "")
            }
        }
        return earned
    }

    // MARK: reset

    func resetAll() {
        for entity in ["FieldProgressEntity", "RunRecordEntity", "SeedEntity", "RibbonEntity",
                       "DailyRunEntity", "MillPaintEntity"] { deleteAll(entity) }
        stats.totalSeedsSown = 0
        stats.totalPodsFlung = 0
        stats.totalPlotsSown = 0
        stats.totalTrueSows = 0
        stats.bestStreak = 0
        stats.totalStars = 0
        stats.fieldsSown = 0
        stats.totalRuns = 0
        stats.totalWins = 0
        stats.lastPlayedAt = nil
        stats.bushels = 0
        stats.rank = 1
        stats.dailyStreak = 0
        stats.bestDailyStreak = 0
        stats.lastDailyKey = nil
        stats.dailyCompleted = 0
        stats.goldenSown = 0
        preference.selectedSeedKey = SeedCatalog.defaultKey
        preference.selectedPaintKey = PaintCatalog.defaultKey
        preference.lastFieldIndex = 0
        preference.firstLaunchCompleted = false
        try? context.save()
        seedContentIfNeeded()
        save()
    }

    // MARK: screenshot tour

    /// Populates the in-memory tour store with one self-consistent farm: ledger rows are generated first and
    /// every other number (field bests, stars, attempts, lifetime stats, seeds, bushels, rank, dailies, ribbons)
    /// is derived from them.
    func seedTourProgress() {
        let now = Date()
        let fields = fieldProgress()
        let starPattern: [Int16] = [3, 3, 2, 3, 2, 3, 1, 2, 3, 3, 2, 3, 2, 2, 3, 1, 2, 3, 3, 2, 2, 3, 1]
        let sownCount = starPattern.count

        struct Plan { let field: Int; let won: Bool; let stars: Int16 }
        var plans: [Plan] = []
        for i in 0..<sownCount {
            if i % 4 == 2 { plans.append(Plan(field: i, won: false, stars: 0)) }
            plans.append(Plan(field: i, won: true, stars: starPattern[i]))
        }
        for i in [0, 4, 9, 14] { plans.append(Plan(field: i, won: true, stars: starPattern[i])) }
        plans.append(Plan(field: sownCount, won: false, stars: 0))

        func score(_ def: FieldDefinition, stars: Int16, salt: Int) -> Int {
            switch stars {
            case 3: return def.score3 + 180 + (salt * 37) % 420
            case 2: return (def.score2 + def.score3) / 2 + (salt * 17) % 140
            case 1: return def.quota * 100 + (salt * 13) % 150
            default: return def.quota * 55 + (salt * 11) % 200
            }
        }

        var records: [RunRecordEntity] = []
        var cleared = Set<Int>()
        var clearedRegions = Set<RegionKey>()
        for (n, plan) in plans.enumerated() {
            let def = FieldCatalog.field(plan.field)
            let salt = n * 7 + plan.field
            let unlockedSeeds = SeedCatalog.all.filter { $0.unlockField <= plan.field }
            let seed = unlockedSeeds[(n * 3) % unlockedSeeds.count]
            let firstClear = plan.won && !cleared.contains(plan.field)
            let podsLeft: Int
            if !plan.won {
                podsLeft = 0
            } else if plan.field == 0 && firstClear {
                podsLeft = 6
            } else if plan.stars == 3 {
                podsLeft = max(def.podsLeftFor3, 2 + salt % 3)
            } else {
                podsLeft = 1 + salt % 2
            }
            let plots = plan.won ? min(def.sowableCount, def.quota + salt % 3) : max(2, def.quota - 3 - salt % 3)
            let streak = plan.field == 11 && plan.won ? 9 : (plan.won ? 3 + (salt * 5) % 6 : 1 + salt % 3)
            var bushels = ProgressionRules.bushels(won: plan.won, stars: Int(plan.stars), plotsSown: plots, goldenSown: 0,
                                                   firstClear: firstClear, daily: false, firstDailyToday: false)
            if firstClear {
                cleared.insert(plan.field)
                let region = def.region
                if !clearedRegions.contains(region.key),
                   region.fields.allSatisfy({ cleared.contains($0 - 1) }) {
                    clearedRegions.insert(region.key)
                    bushels += region.clearBonus
                }
            }

            let r = RunRecordEntity(context: context)
            r.id = UUID()
            r.createdAt = now.addingTimeInterval(-600 - Double(plans.count - 1 - n) * 9_400)
            r.fieldIndex = Int16(def.index)
            r.regionKey = def.region.key.rawValue
            r.score = Int32(score(def, stars: plan.stars, salt: salt))
            r.plotsSown = Int16(plots)
            r.plotsRequired = Int16(def.quota)
            r.podsLeft = Int16(podsLeft)
            r.podsUsed = Int16(def.pods - podsLeft)
            r.bestStreak = Int16(streak)
            r.trueSows = Int16(plan.won ? 1 + salt % 4 : salt % 2)
            r.seedsLost = Int16(2 + salt % 5)
            r.goldenSown = 0
            r.seedKey = seed.key
            r.durationSeconds = Double(55 + (salt * 23) % 80)
            r.outcome = plan.won ? "sown" : "fallow"
            r.starsEarned = plan.stars
            r.bushels = Int16(bushels)
            records.append(r)

            if let f = fields.first(where: { Int($0.fieldIndex) == plan.field }) {
                f.attempts += 1
                f.lastPlayedAt = r.createdAt
                if plan.won {
                    f.stars = max(f.stars, plan.stars)
                    if r.score > f.bestScore {
                        f.bestScore = r.score
                        f.bestPodsLeft = r.podsLeft
                    }
                    f.bestStreak = max(f.bestStreak, r.bestStreak)
                    f.bestTrueSows = max(f.bestTrueSows, r.trueSows)
                    if f.completedAt == nil { f.completedAt = r.createdAt }
                }
            }
        }
        refreshUnlocks(fields)

        // Daily Sowing: a four-day streak running into today (today still open), one run per played day.
        let today = DailyRules.dayKey(for: now)
        let dailyPattern: [(Int, Bool, Int16)] = [(-1, true, 3), (-2, true, 2), (-3, true, 3), (-4, true, 1),
                                                  (-5, false, 0), (-6, true, 2), (-7, true, 2), (-8, true, 1)]
        for (n, (offset, done, dayStars)) in dailyPattern.enumerated() {
            let key = DailyRules.key(today, offsetDays: offset)
            let def = FieldCatalog.daily(dayKey: key)
            let seedKey = ["flax", "rye", "poppy", "sunflower"][n % 4]
            let plots = done ? def.quota + n % 2 : max(2, def.quota - 4)
            let golden = done ? min(2, def.goldenCount) : 1
            let dayScore = score(def, stars: dayStars, salt: n * 5) + golden * ScoreRules.goldenBonus
            let r = RunRecordEntity(context: context)
            r.id = UUID()
            r.createdAt = (DailyRules.date(from: key) ?? now).addingTimeInterval(3_600)
            r.fieldIndex = -1
            r.regionKey = def.region.key.rawValue
            r.dailyKey = key
            r.score = Int32(dayScore)
            r.plotsSown = Int16(plots)
            r.plotsRequired = Int16(def.quota)
            r.podsLeft = Int16(done ? max(def.podsLeftFor3, 2) : 0)
            r.podsUsed = Int16(def.pods - Int(r.podsLeft))
            r.bestStreak = Int16(done ? 4 + n % 3 : 2)
            r.trueSows = Int16(done ? 2 : 0)
            r.seedsLost = Int16(3 + n % 3)
            r.goldenSown = Int16(golden)
            r.seedKey = seedKey
            r.durationSeconds = Double(70 + n * 9)
            r.outcome = done ? "sown" : "fallow"
            r.starsEarned = dayStars
            r.bushels = Int16(ProgressionRules.bushels(won: done, stars: Int(dayStars), plotsSown: plots, goldenSown: golden,
                                                      firstClear: false, daily: true, firstDailyToday: done))
            records.append(r)

            let d = dailyEntry(for: key)
            d.attempts = 1
            d.completed = done
            d.bestScore = done ? r.score : 0
            d.stars = dayStars
            d.completedAt = done ? r.createdAt : nil
            d.seedKey = seedKey
        }

        // Lifetime numbers, straight from the ledger.
        let wins = records.filter { $0.outcome == "sown" }
        stats.totalRuns = Int32(records.count)
        stats.totalWins = Int32(wins.count)
        stats.totalPodsFlung = Int64(records.reduce(0) { $0 + Int($1.podsUsed) })
        stats.totalPlotsSown = Int64(records.reduce(0) { $0 + Int($1.plotsSown) })
        stats.totalTrueSows = Int32(records.reduce(0) { $0 + Int($1.trueSows) })
        stats.goldenSown = Int32(records.reduce(0) { $0 + Int($1.goldenSown) })
        stats.totalSeedsSown = stats.totalPlotsSown + Int64(records.reduce(0) { $0 + Int($1.trueSows) + 2 })
        stats.bestStreak = records.map(\.bestStreak).max() ?? 0
        stats.bushels = Int64(records.reduce(0) { $0 + Int($1.bushels) })
        stats.rank = Int16(RankCatalog.rank(for: Int(stats.bushels)).level)
        stats.totalStars = Int16(fields.reduce(0) { $0 + Int($1.stars) })
        stats.fieldsSown = Int16(fields.filter { $0.stars > 0 }.count)
        stats.lastPlayedAt = records.compactMap(\.createdAt).max()
        let doneDays = Set(dailyEntities().filter(\.completed).compactMap(\.dayKey))
        stats.dailyCompleted = Int32(doneDays.count)
        stats.dailyStreak = Int16(DailyRules.streak(completed: doneDays, today: today))
        stats.bestDailyStreak = Int16(doneDays.map { DailyRules.streak(completed: doneDays, today: $0) }.max() ?? 0)
        stats.lastDailyKey = doneDays.max()

        // Seed usage from the same rows.
        let highestSown = fields.filter { $0.stars > 0 }.map { Int($0.fieldIndex) + 1 }.max() ?? 0
        for seed in seedEntities() {
            let used = records.filter { $0.seedKey == seed.key }
            seed.isUnlocked = Int(seed.unlockField) <= highestSown
            seed.timesUsed = Int32(used.count)
            seed.plotsSown = Int32(used.reduce(0) { $0 + Int($1.plotsSown) })
            seed.bestScore = used.filter { $0.outcome == "sown" }.map(\.score).max() ?? 0
        }

        _ = refreshPaintUnlocks()
        preference.firstLaunchCompleted = true
        preference.selectedSeedKey = "flax"
        preference.selectedPaintKey = "cobalt"
        preference.lastFieldIndex = Int16(sownCount)
        _ = evaluateRibbons(run: nil, firstAttempt: false, fields: fields)
        // skill ribbons the ledger above actually shows (3★ with 6 pods, a x9 streak, windy Terraced fields)
        let skillEarned: [String: Double] = ["noPodLeft": 20, "crowShy": 12, "windwardSower": 0,
                                             "longThrow": 40, "chainOfNine": 25]
        for ribbon in ribbonEntities() {
            if let hoursAgo = skillEarned[ribbon.key ?? ""] {
                ribbon.isEarned = true
                ribbon.progress = ribbon.goal
                ribbon.earnedAt = now.addingTimeInterval(-hoursAgo * 3_600)
            } else if ribbon.isEarned {
                ribbon.earnedAt = now.addingTimeInterval(-3_600 - Double(ribbon.sortIndex + 1) * 9_000)
            }
        }
        save()
    }
}
