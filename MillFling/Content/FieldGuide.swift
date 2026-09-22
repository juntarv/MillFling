import Foundation

enum GuideShelf: String, CaseIterable, Identifiable {
    case plots, hazards, air, skills
    var id: String { rawValue }
    var title: String {
        switch self {
        case .plots: return "Plots"
        case .hazards: return "Hazards"
        case .air: return "Air"
        case .skills: return "Skills"
        }
    }
}

enum GuideArt: Equatable {
    case image(String)
    case tile(PlotKind)
    case target
    case streak
}

/// Lifetime number shown under an entry, read from FarmStatsEntity.
enum GuideStat: Equatable {
    case none, plotsSown, goldenSown, podsFlung, seedsSown, trueSows, bestStreak, runs
}

struct GuideEntry: Identifiable, Equatable {
    let key: String
    let shelf: GuideShelf
    let title: String
    let art: GuideArt
    let body: String
    let tip: String
    /// 0-based field index where the entry first appears; discovered once that field is unlocked.
    let firstField: Int
    let stat: GuideStat
    let statLabel: String
    var id: String { key }
}

enum FieldGuideCatalog {
    static let all: [GuideEntry] = [
        GuideEntry(key: "soil", shelf: .plots, title: "Soil plot", art: .tile(.soil),
                   body: "Brown furrows waiting for seed. Every plot you sow counts toward the field's quota and scores 100, multiplied by your streak.",
                   tip: "A seed that lands on a plot you already sowed is simply resown — no harm, no points.",
                   firstField: 0, stat: .plotsSown, statLabel: "plots sown"),
        GuideEntry(key: "golden", shelf: .plots, title: "Golden plot", art: .tile(.golden),
                   body: "A sun-stitched plot worth +250 on top of the usual score. It still counts toward the quota.",
                   tip: "Marigold and Spelt pay golden plots twice.",
                   firstField: 36, stat: .goldenSown, statLabel: "golden plots sown"),
        GuideEntry(key: "pond", shelf: .hazards, title: "Pond", art: .tile(.pond),
                   body: "Blue water between the strips. Seeds that splash in are gone for good.",
                   tip: "Heavy seeds drop steeply — use them to thread the strips between ponds.",
                   firstField: 9, stat: .none, statLabel: ""),
        GuideEntry(key: "stone", shelf: .hazards, title: "Stone wall", art: .image("stone_wall"),
                   body: "Old walls and orchard trunks. A seed that hits stone bounces off and is wasted.",
                   tip: "Sow the plot just past a wall to earn Stone Skipper.",
                   firstField: 18, stat: .none, statLabel: ""),
        GuideEntry(key: "cart", shelf: .hazards, title: "Hay cart & road", art: .image("hay_cart"),
                   body: "Carts roll back and forth along the road rows. Seeds on the road or in the hay are lost.",
                   tip: "Wait until the cart turns at the end of the road, then burst over the gap.",
                   firstField: 27, stat: .none, statLabel: ""),
        GuideEntry(key: "crow", shelf: .hazards, title: "Crow", art: .image("crow_hazard"),
                   body: "Crows cross the sky band. Any pod or seed they touch is stolen mid-air.",
                   tip: "Lupin and Sorghum punch straight through a crow.",
                   firstField: 6, stat: .none, statLabel: ""),
        GuideEntry(key: "wind", shelf: .air, title: "Crosswind", art: .image("windvane_icon"),
                   body: "The vane and the drifting chaff show the wind. It pushes every airborne seed sideways — light seeds more than heavy ones.",
                   tip: "Release a little early into a headwind, a little late with a tailwind.",
                   firstField: 1, stat: .none, statLabel: ""),
        GuideEntry(key: "shift", shelf: .air, title: "Turning wind", art: .image("cloud_puff"),
                   body: "From Terraced Slopes the wind changes direction mid-run. Watch the vane flip before every throw.",
                   tip: "In the Harvest Crown it gusts every five seconds.",
                   firstField: 18, stat: .none, statLabel: ""),
        GuideEntry(key: "release", shelf: .skills, title: "Release", art: .image("pod_on_sail"),
                   body: "Tap once and the pod leaves the sail on its tangent. Early is high and short; late is flat and far.",
                   tip: "Lobs carry deeper into the field than flat throws.",
                   firstField: 0, stat: .podsFlung, statLabel: "pods flung"),
        GuideEntry(key: "burst", shelf: .skills, title: "Burst", art: .image("pod_burst"),
                   body: "Tap again in flight to split the pod into a fan of seeds. Burst early for a short scatter, late for a long one.",
                   tip: "A pod that lands without bursting still sows the plot it hits.",
                   firstField: 0, stat: .seedsSown, statLabel: "seeds sown"),
        GuideEntry(key: "truesow", shelf: .skills, title: "True sow", art: .target,
                   body: "A seed that lands near the centre of a plot blooms for a bonus on top of the plot score.",
                   tip: "Buckwheat and Pumpkin bloom loudest.",
                   firstField: 0, stat: .trueSows, statLabel: "true sows"),
        GuideEntry(key: "streak", shelf: .skills, title: "Streak", art: .streak,
                   body: "Every pod that sows at least one plot grows the streak, up to x4 points. An empty pod resets it.",
                   tip: "Lavender forgives the first empty pod of each field.",
                   firstField: 0, stat: .bestStreak, statLabel: "best streak"),
        GuideEntry(key: "daily", shelf: .skills, title: "Daily Sowing", art: .image("icon_app_mark"),
                   body: "One new field every calendar day, built from the valley's layouts with two golden plots and a spare pod.",
                   tip: "Sow it on consecutive days to grow a streak toward the 30-day ribbon.",
                   firstField: 0, stat: .runs, statLabel: "runs finished")
    ]

    static func entry(_ key: String?) -> GuideEntry? { all.first { $0.key == key } }
}
