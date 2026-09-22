import Foundation

// MARK: - Farmer ranks

struct Rank: Equatable, Identifiable {
    let level: Int
    let title: String
    /// Lifetime bushels needed to reach this rank.
    let threshold: Int
    var id: Int { level }
}

enum RankCatalog {
    static let all: [Rank] = [
        Rank(level: 1, title: "Sprout Hand", threshold: 0),
        Rank(level: 2, title: "Seed Carrier", threshold: 80),
        Rank(level: 3, title: "Furrow Walker", threshold: 200),
        Rank(level: 4, title: "Sail Watcher", threshold: 360),
        Rank(level: 5, title: "Furrow Hand", threshold: 560),
        Rank(level: 6, title: "Plot Keeper", threshold: 800),
        Rank(level: 7, title: "Wind Reader", threshold: 1_100),
        Rank(level: 8, title: "Burst Caller", threshold: 1_450),
        Rank(level: 9, title: "Field Steward", threshold: 1_850),
        Rank(level: 10, title: "Sail Master", threshold: 2_300),
        Rank(level: 11, title: "Crow Chaser", threshold: 2_800),
        Rank(level: 12, title: "Terrace Warden", threshold: 3_400),
        Rank(level: 13, title: "Storm Sower", threshold: 4_050),
        Rank(level: 14, title: "Coast Keeper", threshold: 4_750),
        Rank(level: 15, title: "Orchard Elder", threshold: 5_500),
        Rank(level: 16, title: "Linen Weaver", threshold: 6_300),
        Rank(level: 17, title: "Harvest Reeve", threshold: 7_200),
        Rank(level: 18, title: "Golden Hand", threshold: 8_200),
        Rank(level: 19, title: "Crown Sower", threshold: 9_300),
        Rank(level: 20, title: "Mill Legend", threshold: 10_500)
    ]

    static func rank(for bushels: Int) -> Rank {
        all.last { bushels >= $0.threshold } ?? all[0]
    }

    static func next(after rank: Rank) -> Rank? {
        all.first { $0.level == rank.level + 1 }
    }

    /// 0...1 progress from the current rank toward the next one (1 at max rank).
    static func progress(bushels: Int) -> Double {
        let current = rank(for: bushels)
        guard let next = next(after: current) else { return 1 }
        return Double(bushels - current.threshold) / Double(max(1, next.threshold - current.threshold))
    }
}

enum ProgressionRules {
    /// Bushels (farm XP) for one finished run.
    static func bushels(won: Bool, stars: Int, plotsSown: Int, goldenSown: Int,
                        firstClear: Bool, daily: Bool, firstDailyToday: Bool) -> Int {
        guard won else { return 6 + plotsSown }
        var total = 30 + stars * 15 + plotsSown * 2 + goldenSown * 5
        if firstClear { total += 40 }
        if daily { total += 30 }
        if firstDailyToday { total += 40 }
        return total
    }
}

// MARK: - Daily Sowing

enum DailyRules {
    static let milestones = [3, 7, 14, 30]

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    static func key(_ key: String, offsetDays: Int, calendar: Calendar = .current) -> String {
        guard let d = date(from: key, calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: offsetDays, to: d) else { return key }
        return dayKey(for: moved, calendar: calendar)
    }

    /// Stable 64-bit seed from the day key (FNV-1a).
    static func seed(for key: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    /// Consecutive completed days ending today — or yesterday, while today is still open.
    static func streak(completed: Set<String>, today: String) -> Int {
        var cursor = completed.contains(today) ? today : key(today, offsetDays: -1)
        var count = 0
        while completed.contains(cursor) && count < 3_650 {
            count += 1
            cursor = key(cursor, offsetDays: -1)
        }
        return count
    }

    /// The last `count` day keys ending with `today`, oldest first.
    static func recentKeys(count: Int, today: String) -> [String] {
        (0..<count).reversed().map { key(today, offsetDays: -$0) }
    }

    static func nextMilestone(after streak: Int) -> Int? {
        milestones.first { $0 > streak }
    }

    static func shortLabel(_ key: String) -> String {
        guard let d = date(from: key) else { return key }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE d"
        return f.string(from: d)
    }

    static func longLabel(_ key: String) -> String {
        guard let d = date(from: key) else { return key }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: d)
    }

    static func timeUntilTomorrow(from now: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        let seconds = max(0, Int(tomorrow.timeIntervalSince(now)))
        return String(format: "%dh %02dm", seconds / 3_600, (seconds % 3_600) / 60)
    }
}

// MARK: - Mill paints

struct MillPaint: Identifiable, Equatable {
    let key: String
    let name: String
    let hex: UInt32
    let unlockRank: Int
    let lore: String
    let sortIndex: Int
    var id: String { key }
}

enum PaintCatalog {
    static let defaultKey = "sunflower"

    static let all: [MillPaint] = [
        MillPaint(key: "sunflower", name: "Sunflower", hex: 0xFFC01F, unlockRank: 1, lore: "The colour the mill was born in.", sortIndex: 0),
        MillPaint(key: "cobalt", name: "Cobalt Sky", hex: 0x3D86F0, unlockRank: 3, lore: "Sails that vanish into the noon sky.", sortIndex: 1),
        MillPaint(key: "poppy", name: "Poppy Red", hex: 0xE0483C, unlockRank: 5, lore: "Stitch-red, bright enough to guide the crows away.", sortIndex: 2),
        MillPaint(key: "linen", name: "Bleached Linen", hex: 0xFFF6E4, unlockRank: 7, lore: "Sun-washed canvas, the old way.", sortIndex: 3),
        MillPaint(key: "meadow", name: "Meadow Green", hex: 0x3FB073, unlockRank: 9, lore: "The green of the first sprouts.", sortIndex: 4),
        MillPaint(key: "amber", name: "Amber Honey", hex: 0xF09A0C, unlockRank: 11, lore: "Late-summer amber, warm as a hive.", sortIndex: 5),
        MillPaint(key: "morning", name: "Morning Blue", hex: 0x8FC0FF, unlockRank: 13, lore: "The pale blue before the heat.", sortIndex: 6),
        MillPaint(key: "rust", name: "Rust Stitch", hex: 0xB5532E, unlockRank: 15, lore: "Barn-paint rust from the Orchard Rows.", sortIndex: 7),
        MillPaint(key: "navy", name: "Night Navy", hex: 0x1E3F8A, unlockRank: 17, lore: "Ink-dark sails for a seasoned hand.", sortIndex: 8),
        MillPaint(key: "crown", name: "Crown Gold", hex: 0xFFDE6A, unlockRank: 19, lore: "Pale gold, only for the Crown Sowers.", sortIndex: 9)
    ]

    static func paint(_ key: String?) -> MillPaint {
        all.first { $0.key == key } ?? all[0]
    }
}
