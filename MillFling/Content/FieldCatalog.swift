import Foundation

enum PlotKind: Equatable {
    case soil, pond, stone, road, golden
    var isSowable: Bool { self == .soil || self == .golden }
    var isHazard: Bool { self == .pond || self == .stone || self == .road }
}

/// Wind in "vane units": positive blows east (to the right), negative west.
struct WindProfile: Equatable {
    let base: Double
    /// Seconds between shifts; nil = steady for the whole run.
    let shiftEvery: Double?
    /// Values cycled through at every shift (starts with `base`).
    let sequence: [Double]

    func value(at time: Double) -> Double {
        guard let every = shiftEvery, every > 0, !sequence.isEmpty else { return base }
        let step = Int(time / every)
        return sequence[step % sequence.count]
    }

    var peak: Double { sequence.map(abs).max() ?? abs(base) }
    var summary: String {
        if peak < 0.05 { return "Calm" }
        guard let every = shiftEvery else { return Format.wind(base) + " steady" }
        return Format.wind(base) + " · turns every \(Int(every)) s"
    }

    static let calm = WindProfile(base: 0, shiftEvery: nil, sequence: [0])
}

struct FieldDefinition: Identifiable, Equatable {
    let index: Int           // 0-based campaign index; daily fields use -1
    let region: Region
    let rows: Int
    let cols: Int
    /// Row-major, row 0 is the far row next to the mill.
    let layout: [PlotKind]
    let quota: Int
    let pods: Int
    let sailSpeed: Double    // rad/s, clockwise
    let throwScale: Double
    let wind: WindProfile
    let crows: Int
    let carts: Int
    let score2: Int
    let score3: Int
    let podsLeftFor3: Int
    let tip: String?
    /// Set for Daily Sowing fields ("yyyy-MM-dd").
    var dailyKey: String? = nil

    var id: String { dailyKey.map { "daily-\($0)" } ?? "field-\(index)" }
    var number: Int { index + 1 }
    var isDaily: Bool { dailyKey != nil }
    var sowableCount: Int { layout.filter(\.isSowable).count }
    var goldenCount: Int { layout.filter { $0 == .golden }.count }
    var pondCount: Int { layout.filter { $0 == .pond }.count }
    var stoneCount: Int { layout.filter { $0 == .stone }.count }
    var roadCount: Int { layout.filter { $0 == .road }.count }
    var title: String { isDaily ? "Daily Sowing" : "Field \(number)" }

    func kind(row: Int, col: Int) -> PlotKind { layout[row * cols + col] }

    /// Stars for a finished run: 0 = fallow.
    func stars(score: Int, plotsSown: Int, podsLeft: Int) -> Int {
        guard plotsSown >= quota else { return 0 }
        if score >= score3 && podsLeft >= podsLeftFor3 { return 3 }
        if score >= score2 { return 2 }
        return 1
    }

    /// Short hazard list for briefings and the ledger.
    var hazardLines: [String] {
        var lines: [String] = []
        if pondCount > 0 { lines.append("\(pondCount) pond\(pondCount == 1 ? "" : "s")") }
        if stoneCount > 0 { lines.append("\(stoneCount) stone wall\(stoneCount == 1 ? "" : "s")") }
        if roadCount > 0 { lines.append("\(roadCount) road plot\(roadCount == 1 ? "" : "s")") }
        if crows > 0 { lines.append(crows == 1 ? "1 crow" : "\(crows) crows") }
        if carts > 0 { lines.append(carts == 1 ? "1 hay cart" : "\(carts) hay carts") }
        if goldenCount > 0 { lines.append("\(goldenCount) golden plot\(goldenCount == 1 ? "" : "s")") }
        return lines
    }
}

enum FieldCatalog {
    static let count = 72

    static let all: [FieldDefinition] = (0..<count).map { make($0, seed: UInt64(1_000 + $0 * 97)) }

    static func field(_ index: Int) -> FieldDefinition {
        all[max(0, min(count - 1, index))]
    }

    /// Scripted field used by `-demoMode` and the screenshot tour: a Lakeside layout with a 1.6 E wind.
    static let demo: FieldDefinition = {
        let base = make(11, seed: UInt64(1_000 + 11 * 97))
        return FieldDefinition(index: base.index, region: base.region, rows: base.rows, cols: base.cols,
                               layout: base.layout, quota: base.quota, pods: base.pods,
                               sailSpeed: 1.9, throwScale: base.throwScale,
                               wind: WindProfile(base: 1.6, shiftEvery: nil, sequence: [1.6]),
                               crows: 1, carts: 0, score2: base.score2, score3: base.score3,
                               podsLeftFor3: base.podsLeftFor3, tip: nil)
    }()

    /// Daily Sowing: one field per calendar day, built from a template region and a date seed.
    static func daily(dayKey: String) -> FieldDefinition {
        let seed = DailyRules.seed(for: dayKey)
        var rng = SeededRandom(seed: seed)
        // Days cycle through the templates of regions 2-7 so every day plays differently.
        let template = 9 + rng.int(54)
        let base = make(template, seed: seed)
        var layout = base.layout
        // every daily field carries two golden plots
        var golden = layout.filter { $0 == .golden }.count
        var guardCount = 0
        while golden < 2 && guardCount < 60 {
            guardCount += 1
            let i = rng.int(layout.count)
            if layout[i] == .soil { layout[i] = .golden; golden += 1 }
        }
        let quota = min(base.quota, layout.filter(\.isSowable).count - 2)
        return FieldDefinition(index: -1, region: base.region, rows: base.rows, cols: base.cols,
                               layout: layout, quota: quota, pods: base.pods + 1,
                               sailSpeed: min(3.6, base.sailSpeed), throwScale: 1,
                               wind: base.wind, crows: base.crows, carts: base.carts,
                               score2: quota * 160 + 300, score3: quota * 225 + 600,
                               podsLeftFor3: max(2, (base.pods + 1) / 4),
                               tip: "Today's field — one best score per day keeps your streak alive.",
                               dailyKey: dayKey)
    }

    /// Sail speed: the original 1.6 → 3.8 curve for fields 1-36, then 3.4 → 4.4 for the late regions.
    static func sailSpeed(_ i: Int) -> Double {
        if i < 36 { return 1.6 + 2.2 * Double(i) / 35 }
        return 3.4 + 1.0 * Double(i - 36) / 35
    }

    private static func make(_ i: Int, seed: UInt64) -> FieldDefinition {
        let regionIndex = min(i / 9, Region.all.count - 1)
        let region = Region.all[regionIndex]
        let t = Double(i % 9) / 8.0
        var rng = SeededRandom(seed: seed)

        let shapes: [(Int, Int)] = [(3, 5), (4, 5), (4, 6), (5, 6), (4, 6), (5, 6), (5, 6), (5, 6)]
        let (rows, cols) = shapes[regionIndex]
        let quota: Int
        let pods: Int
        switch regionIndex {
        case 0: quota = 6 + Int((t * 6).rounded()); pods = 14 - Int((t * 2).rounded())
        case 1: quota = 12 + Int((t * 4).rounded()); pods = 13 - Int((t * 2).rounded())
        case 2: quota = 14 + Int((t * 4).rounded()); pods = 12 - Int((t * 2).rounded())
        case 3: quota = 16 + Int((t * 6).rounded()); pods = 12 - Int((t * 2).rounded())
        case 4: quota = 14 + Int((t * 4).rounded()); pods = 12 - Int((t * 2).rounded())
        case 5: quota = 17 + Int((t * 4).rounded()); pods = 12 - Int((t * 2).rounded())
        case 6: quota = 17 + Int((t * 4).rounded()); pods = 11 - Int(t.rounded())
        default: quota = 18 + Int((t * 4).rounded()); pods = 11 - Int(t.rounded())
        }

        // --- wind ---
        let sign: Double = (i % 2 == 0) ? 1 : -1
        let magnitude: Double
        switch regionIndex {
        case 0: magnitude = t * 0.8
        case 1: magnitude = 0.8 + t * 1.2
        case 2: magnitude = 1.2 + t * 1.2
        case 3: magnitude = 2.0 + t * 1.4
        case 4: magnitude = 2.0 + t * 1.0
        case 5: magnitude = 1.6 + t * 1.2
        case 6: magnitude = 1.2 + t * 1.2
        default: magnitude = 2.4 + t * 1.2
        }
        let base = (magnitude * 10).rounded() / 10 * sign
        let wind: WindProfile
        switch regionIndex {
        case 2: wind = WindProfile(base: base, shiftEvery: 14, sequence: [base, -base * 0.8])
        case 3: wind = WindProfile(base: base, shiftEvery: 6, sequence: [base, -base, base * 0.6])
        case 5: wind = WindProfile(base: base, shiftEvery: 10, sequence: [base, -base * 0.7])
        case 6: wind = WindProfile(base: base, shiftEvery: 12, sequence: [base, base * 0.4, -base])
        case 7: wind = WindProfile(base: base, shiftEvery: 5, sequence: [base, -base * 0.9, base * 0.5, -base])
        default: wind = i == 0 ? .calm : WindProfile(base: base, shiftEvery: nil, sequence: [base])
        }

        // --- hazards ---
        var layout = Array(repeating: PlotKind.soil, count: rows * cols)
        var hazardBudget = rows * cols - quota - 2
        func place(_ kind: PlotKind, _ amount: Int, rowsAllowed: ClosedRange<Int>) {
            var placed = 0
            var guardCount = 0
            while placed < amount && (kind == .golden || hazardBudget > 0) && guardCount < 200 {
                guardCount += 1
                let r = rowsAllowed.lowerBound + rng.int(rowsAllowed.count)
                let c = rng.int(cols)
                let idx = r * cols + c
                if layout[idx] == .soil {
                    layout[idx] = kind
                    placed += 1
                    if kind != .golden { hazardBudget -= 1 }
                }
            }
        }
        func road(row: Int, cells: Int) {
            let n = min(cells, hazardBudget)
            guard n > 0 else { return }
            let startCol = rng.int(cols - n + 1)
            for c in startCol..<(startCol + n) where layout[row * cols + c] == .soil {
                layout[row * cols + c] = .road
                hazardBudget -= 1
            }
        }
        var crows = 0
        var carts = 0
        switch regionIndex {
        case 0:
            crows = i >= 6 ? 1 : 0
        case 1:
            place(.pond, 2 + i % 3, rowsAllowed: 0...(rows - 1))
            crows = i % 2 == 1 ? 1 : 0
        case 2:
            place(.stone, 2 + i % 2, rowsAllowed: 0...(rows - 2))
            place(.pond, 1, rowsAllowed: 1...(rows - 1))
            crows = 1
        case 3:
            road(row: 2, cells: 3)
            place(.stone, 2, rowsAllowed: 0...1)
            crows = 2
            carts = 1
        case 4:
            place(.pond, 3 + i % 2, rowsAllowed: 0...(rows - 1))
            place(.golden, 2, rowsAllowed: 0...(rows - 1))
            crows = 1
        case 5:
            place(.stone, 3 + i % 2, rowsAllowed: 0...(rows - 2))
            place(.golden, 2, rowsAllowed: 1...(rows - 1))
            crows = 2
        case 6:
            road(row: 1, cells: 2)
            road(row: 3, cells: 3)
            place(.pond, 1, rowsAllowed: 0...(rows - 1))
            place(.golden, 3, rowsAllowed: 0...(rows - 1))
            crows = 1
            carts = 2
        default:
            road(row: 1, cells: 2)
            road(row: 3, cells: 2)
            place(.stone, 1, rowsAllowed: 0...2)
            place(.golden, 3, rowsAllowed: 0...(rows - 1))
            crows = 3
            carts = 2
        }

        let tip: String?
        switch i {
        case 0: tip = "Tap to let the pod go, tap again to burst it."
        case 1: tip = "Burst early for a short scatter, late for a long one."
        case 6: tip = "A crow is out. Seeds it touches are gone."
        case 9: tip = "Ponds swallow seeds. Aim for the soil strips."
        case 18: tip = "Stone walls waste a seed. The wind will turn mid-run."
        case 27: tip = "Hay carts roll along the road. Wait for a gap."
        case 36: tip = "Golden plots bloom for +250. They count toward the quota."
        case 45: tip = "Two crows patrol the orchard. Burst low under them."
        case 54: tip = "Two carts cross the valley. Watch both roads."
        case 63: tip = "The Crown gusts every five seconds. Read the vane before each throw."
        default: tip = nil
        }

        let goldenBonus = layout.filter { $0 == .golden }.count * 180
        return FieldDefinition(
            index: i, region: region, rows: rows, cols: cols, layout: layout,
            quota: quota, pods: pods,
            sailSpeed: sailSpeed(i),
            throwScale: 1.0,
            wind: wind, crows: crows, carts: carts,
            score2: quota * 150 + 250 + goldenBonus,
            score3: quota * 210 + 500 + goldenBonus,
            podsLeftFor3: max(2, pods / 4),
            tip: tip)
    }
}
