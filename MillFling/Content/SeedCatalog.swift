import Foundation

enum SeedTrait: Equatable {
    case none
    case crowProof      // Lupin, Sorghum: punches through crows
    case secondBurst    // Vetch: one extra burst per run
    case extraPod       // Oat: +1 pod per field
    case steadyHand     // Pea: sails turn 15% slower
    case goldenTouch    // Marigold, Spelt: golden plots pay double
    case luckyStreak    // Lavender: the first empty throw keeps the streak

    var summary: String? {
        switch self {
        case .none: return nil
        case .crowProof: return "Crow-proof: seeds punch through crows."
        case .secondBurst: return "Tap again while seeds fall to split them once more, once per field."
        case .extraPod: return "Every field starts with one extra pod."
        case .steadyHand: return "The sails turn 15% slower while this seed rides them."
        case .goldenTouch: return "Golden plots pay double their bonus."
        case .luckyStreak: return "Your streak survives the first empty throw of every field."
        }
    }
}

struct SeedVariety: Identifiable, Equatable {
    let key: String
    let name: String
    let lore: String
    let traitLine: String
    /// 1-based field number that must be sown to unlock; 0 = available from the start.
    let unlockField: Int
    let mass: Double
    let seedsPerBurst: Int
    let drift: Double
    let bloomBonus: Int
    let spread: Double
    let trait: SeedTrait
    let sortIndex: Int

    var id: String { key }
    var imageName: String { "seed_\(key)" }
}

enum SeedCatalog {
    static let defaultKey = "rye"

    static let all: [SeedVariety] = [
        SeedVariety(key: "rye", name: "Rye", lore: "The dependable all-rounder. Middling weight, honest fan, forgives a shaky release.",
                    traitLine: "All-rounder", unlockField: 0, mass: 0.55, seedsPerBurst: 3, drift: 0.45, bloomBonus: 0, spread: 1.0, trait: .none, sortIndex: 0),
        SeedVariety(key: "sunflower", name: "Sunflower", lore: "Heavy striped seeds that shrug off the wind and drop steeply where you burst them.",
                    traitLine: "Heavy", unlockField: 0, mass: 0.90, seedsPerBurst: 3, drift: 0.20, bloomBonus: 10, spread: 0.8, trait: .none, sortIndex: 1),
        SeedVariety(key: "flax", name: "Flax", lore: "Light pods that ride the gust. Forgiving on long throws, easily blown off a narrow strip.",
                    traitLine: "Light", unlockField: 0, mass: 0.34, seedsPerBurst: 4, drift: 0.86, bloomBonus: 0, spread: 1.1, trait: .none, sortIndex: 2),
        SeedVariety(key: "poppy", name: "Poppy", lore: "The widest fan in the crate, five seeds at once, but it never throws far.",
                    traitLine: "5-burst", unlockField: 6, mass: 0.40, seedsPerBurst: 5, drift: 0.62, bloomBonus: 0, spread: 1.35, trait: .none, sortIndex: 3),
        SeedVariety(key: "barley", name: "Barley", lore: "Long, flat throws with whiskered seeds that skate before they settle.",
                    traitLine: "Flat & far", unlockField: 10, mass: 0.62, seedsPerBurst: 4, drift: 0.38, bloomBonus: 0, spread: 0.95, trait: .none, sortIndex: 4),
        SeedVariety(key: "clover", name: "Clover", lore: "Six tiny seeds per burst. Covers ground, but a true sow is worth less.",
                    traitLine: "6-burst", unlockField: 14, mass: 0.30, seedsPerBurst: 6, drift: 0.74, bloomBonus: -35, spread: 1.3, trait: .none, sortIndex: 5),
        SeedVariety(key: "buckwheat", name: "Buckwheat", lore: "Three-cornered seeds that bloom loud: half again the bonus on every true sow.",
                    traitLine: "Bloom +50%", unlockField: 19, mass: 0.70, seedsPerBurst: 3, drift: 0.30, bloomBonus: 38, spread: 0.85, trait: .none, sortIndex: 6),
        SeedVariety(key: "millet", name: "Millet", lore: "Round beads in a balanced spread. Nothing fancy, nothing wasted.",
                    traitLine: "Balanced", unlockField: 22, mass: 0.44, seedsPerBurst: 5, drift: 0.55, bloomBonus: 0, spread: 1.1, trait: .none, sortIndex: 7),
        SeedVariety(key: "mustard", name: "Mustard", lore: "Tiny and restless. It curves hard downwind, which is a gift if you read the vane.",
                    traitLine: "Wind-bent", unlockField: 25, mass: 0.38, seedsPerBurst: 4, drift: 0.95, bloomBonus: 10, spread: 1.0, trait: .none, sortIndex: 8),
        SeedVariety(key: "lupin", name: "Lupin", lore: "Hard-coated seeds that punch straight through a crow without being stolen.",
                    traitLine: "Crow-proof", unlockField: 28, mass: 0.82, seedsPerBurst: 3, drift: 0.24, bloomBonus: 0, spread: 0.85, trait: .crowProof, sortIndex: 9),
        SeedVariety(key: "vetch", name: "Vetch", lore: "Twining pods that can split a second time, once in every field.",
                    traitLine: "Second burst", unlockField: 31, mass: 0.48, seedsPerBurst: 5, drift: 0.66, bloomBonus: 0, spread: 1.05, trait: .secondBurst, sortIndex: 10),
        SeedVariety(key: "oat", name: "Oat", lore: "A patient crop. Every field starts with one extra pod in the hopper.",
                    traitLine: "+1 pod", unlockField: 34, mass: 0.58, seedsPerBurst: 4, drift: 0.42, bloomBonus: 0, spread: 1.0, trait: .extraPod, sortIndex: 11),
        SeedVariety(key: "cornflower", name: "Cornflower", lore: "Blue-eyed and light; a gentler Flax that holds its line a little better.",
                    traitLine: "Light", unlockField: 37, mass: 0.36, seedsPerBurst: 4, drift: 0.70, bloomBonus: 0, spread: 1.15, trait: .none, sortIndex: 12),
        SeedVariety(key: "chamomile", name: "Chamomile", lore: "Five white-petalled seeds that float a long way on warm air.",
                    traitLine: "5-burst", unlockField: 40, mass: 0.32, seedsPerBurst: 5, drift: 0.78, bloomBonus: 15, spread: 1.2, trait: .none, sortIndex: 13),
        SeedVariety(key: "marigold", name: "Marigold", lore: "Orange crowns that love the golden plots and pay them back twice.",
                    traitLine: "Golden x2", unlockField: 42, mass: 0.50, seedsPerBurst: 4, drift: 0.50, bloomBonus: 20, spread: 1.0, trait: .goldenTouch, sortIndex: 14),
        SeedVariety(key: "pea", name: "Pea", lore: "Round and patient. The sails slow down while a pea pod rides them.",
                    traitLine: "Slow sails", unlockField: 45, mass: 0.78, seedsPerBurst: 3, drift: 0.28, bloomBonus: 0, spread: 0.9, trait: .steadyHand, sortIndex: 15),
        SeedVariety(key: "lentil", name: "Lentil", lore: "Flat discs that skid straight and ignore most of the breeze.",
                    traitLine: "Straight", unlockField: 48, mass: 0.66, seedsPerBurst: 5, drift: 0.34, bloomBonus: -10, spread: 1.1, trait: .none, sortIndex: 16),
        SeedVariety(key: "canola", name: "Canola", lore: "Six bright seeds in the widest fan after Clover, great for wide rows.",
                    traitLine: "6-burst", unlockField: 51, mass: 0.42, seedsPerBurst: 6, drift: 0.62, bloomBonus: -20, spread: 1.4, trait: .none, sortIndex: 17),
        SeedVariety(key: "sesame", name: "Sesame", lore: "Featherlight teardrops. Every gust moves them; every calm day rewards them.",
                    traitLine: "Featherlight", unlockField: 54, mass: 0.28, seedsPerBurst: 6, drift: 0.90, bloomBonus: -25, spread: 1.25, trait: .none, sortIndex: 18),
        SeedVariety(key: "lavender", name: "Lavender", lore: "Calming spikes: the first empty throw of a field never breaks your streak.",
                    traitLine: "Lucky streak", unlockField: 57, mass: 0.46, seedsPerBurst: 4, drift: 0.58, bloomBonus: 25, spread: 1.0, trait: .luckyStreak, sortIndex: 19),
        SeedVariety(key: "pumpkin", name: "Pumpkin", lore: "Two huge seeds. Nothing moves them, and a true sow blooms enormous.",
                    traitLine: "Huge bloom", unlockField: 60, mass: 0.98, seedsPerBurst: 2, drift: 0.12, bloomBonus: 60, spread: 0.7, trait: .none, sortIndex: 20),
        SeedVariety(key: "quinoa", name: "Quinoa", lore: "Mountain beads in a tidy five-seed spread with a little bloom on top.",
                    traitLine: "Tidy", unlockField: 63, mass: 0.50, seedsPerBurst: 5, drift: 0.52, bloomBonus: 5, spread: 1.05, trait: .none, sortIndex: 21),
        SeedVariety(key: "spelt", name: "Spelt", lore: "An old grain with golden luck: golden plots pay it double.",
                    traitLine: "Golden x2", unlockField: 66, mass: 0.64, seedsPerBurst: 4, drift: 0.40, bloomBonus: 15, spread: 1.0, trait: .goldenTouch, sortIndex: 22),
        SeedVariety(key: "sorghum", name: "Sorghum", lore: "Dense red heads, heavy enough to shoulder straight through a crow.",
                    traitLine: "Crow-proof", unlockField: 69, mass: 0.86, seedsPerBurst: 4, drift: 0.22, bloomBonus: 20, spread: 0.9, trait: .crowProof, sortIndex: 23)
    ]

    static func variety(_ key: String?) -> SeedVariety {
        all.first { $0.key == key } ?? all[0]
    }
}
