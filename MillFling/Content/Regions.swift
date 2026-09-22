import Foundation

enum RegionKey: String, CaseIterable, Identifiable {
    case meadow, lakeside, terraced, storm, coast, orchard, linen, crown
    var id: String { rawValue }
}

struct Region: Identifiable, Equatable {
    let key: RegionKey
    let order: Int
    let name: String
    let blurb: String
    /// What this region adds to the game, shown on the gate banner and in the briefing.
    let novelty: String
    /// 1-based field numbers inside the region.
    let fields: ClosedRange<Int>
    /// Total ribbon stars needed before the first field of the region opens.
    let starGate: Int
    /// Bushels awarded the first time every field in the region is sown.
    let clearBonus: Int

    var id: String { key.rawValue }
    var fieldCount: Int { fields.count }
    var maxStars: Int { fields.count * 3 }

    static let all: [Region] = [
        Region(key: .meadow, order: 0, name: "Meadow Rise",
               blurb: "Calm air and wide strips. Learn the beat of the sails.",
               novelty: "Gentle breeze, the first crow at field 7", fields: 1...9, starGate: 0, clearBonus: 60),
        Region(key: .lakeside, order: 1, name: "Lakeside Strips",
               blurb: "Ponds cut the field into narrow strips and a crosswind comes off the water.",
               novelty: "Ponds swallow seeds", fields: 10...18, starGate: 8, clearBonus: 80),
        Region(key: .terraced, order: 2, name: "Terraced Slopes",
               blurb: "Stone walls between the plots, and the wind turns once mid-run.",
               novelty: "Stone walls, one wind shift", fields: 19...27, starGate: 34, clearBonus: 100),
        Region(key: .storm, order: 3, name: "Storm Ridge",
               blurb: "Shifting gales, crow pairs and hay carts rolling along the road.",
               novelty: "Hay carts and crow pairs", fields: 28...36, starGate: 62, clearBonus: 120),
        Region(key: .coast, order: 4, name: "Sunflower Coast",
               blurb: "A steady sea breeze over salt inlets, and golden plots that bloom for a bonus.",
               novelty: "Golden plots +250", fields: 37...45, starGate: 84, clearBonus: 140),
        Region(key: .orchard, order: 5, name: "Orchard Rows",
               blurb: "Old trunks stand between the rows and two crows patrol the canopy.",
               novelty: "Tree trunks, wind turns every 10 s", fields: 46...54, starGate: 106, clearBonus: 160),
        Region(key: .linen, order: 6, name: "Linen Valley",
               blurb: "Two cart roads cross the flax beds and the sails turn quick in the valley draught.",
               novelty: "Two carts, faster sails", fields: 55...63, starGate: 128, clearBonus: 180),
        Region(key: .crown, order: 7, name: "Harvest Crown",
               blurb: "Everything at once under the high sun: gusts every five seconds, three crows, two carts.",
               novelty: "Three crows, gusts every 5 s", fields: 64...72, starGate: 150, clearBonus: 220)
    ]

    static func forField(number: Int) -> Region {
        all.first { $0.fields.contains(number) } ?? all[0]
    }

    static func forKey(_ key: String?) -> Region {
        all.first { $0.key.rawValue == key } ?? all[0]
    }
}
