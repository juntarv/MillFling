import Foundation

enum RibbonKey: String, CaseIterable {
    // original sixteen
    case firstFurrow, twelveSown, fullCrate, gustrider, noPodLeft, crowShy, terraceHand, windwardSower
    case trueAim, flaxMaster, longThrow, chainOfNine, stoneSkipper, stormKeeper, almanacFilled, millKeeper
    // regions
    case coastlineSower, orchardKeeper, linenWeaver, crownBearer, meadowPerfect, stillWaters
    // stars
    case fiftyStars, hundredStars, starField
    // golden plots
    case goldenTouch, goldRush
    // daily sowing
    case sunriseSower, threeSuns, weekOfSuns, monthOfSuns, almanacOfDays
    // ranks & collection
    case furrowHand, sailMaster, millLegend, paintedSails, fullHopper
    // skill & endurance
    case everyPodCounts, bigBloom, longSeason
}

enum RibbonCategory: String, CaseIterable, Identifiable {
    case fields, skill, daily, collection
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fields: return "Fields"
        case .skill: return "Skill"
        case .daily: return "Daily"
        case .collection: return "Collection"
        }
    }
}

struct RibbonDefinition: Identifiable {
    let key: RibbonKey
    let title: String
    let detail: String
    let goal: Int
    let category: RibbonCategory
    var id: String { key.rawValue }
}

enum RibbonCatalog {
    static let all: [RibbonDefinition] = [
        RibbonDefinition(key: .firstFurrow, title: "First Furrow", detail: "Sow your first field.", goal: 1, category: .fields),
        RibbonDefinition(key: .twelveSown, title: "Twelve Sown", detail: "Sow twelve different fields.", goal: 12, category: .fields),
        RibbonDefinition(key: .fullCrate, title: "Full Crate", detail: "Sow thirty-six different fields.", goal: 36, category: .fields),
        RibbonDefinition(key: .gustrider, title: "Gustrider", detail: "Sow a plot while the wind blows 3.0 or more.", goal: 1, category: .skill),
        RibbonDefinition(key: .noPodLeft, title: "No Pod Left", detail: "Earn three stars with five or more pods to spare.", goal: 1, category: .skill),
        RibbonDefinition(key: .crowShy, title: "Crow Shy", detail: "Clear a crow field without losing a seed to a crow.", goal: 1, category: .skill),
        RibbonDefinition(key: .terraceHand, title: "Terrace Hand", detail: "Three stars on every Terraced Slopes field.", goal: 9, category: .fields),
        RibbonDefinition(key: .windwardSower, title: "Windward Sower", detail: "Sow a full field with the wind above 2.0.", goal: 1, category: .skill),
        RibbonDefinition(key: .trueAim, title: "True Aim", detail: "Land fifty true sows in the centre of a plot.", goal: 50, category: .skill),
        RibbonDefinition(key: .flaxMaster, title: "Flax Master", detail: "Sow two hundred plots with Flax.", goal: 200, category: .collection),
        RibbonDefinition(key: .longThrow, title: "Long Throw", detail: "Sow a plot on the far right edge of the field.", goal: 1, category: .skill),
        RibbonDefinition(key: .chainOfNine, title: "Chain of Nine", detail: "Reach a x9 streak in a single field.", goal: 1, category: .skill),
        RibbonDefinition(key: .stoneSkipper, title: "Stone Skipper", detail: "Sow the plot just past a stone wall.", goal: 1, category: .skill),
        RibbonDefinition(key: .stormKeeper, title: "Storm Keeper", detail: "Clear a Storm Ridge field on the first try.", goal: 1, category: .fields),
        RibbonDefinition(key: .almanacFilled, title: "Almanac Filled", detail: "Unlock all twenty-four seed varieties.", goal: 24, category: .collection),
        RibbonDefinition(key: .millKeeper, title: "Mill Keeper", detail: "Sow ten thousand seeds in total.", goal: 10_000, category: .collection),
        RibbonDefinition(key: .coastlineSower, title: "Coastline Sower", detail: "Sow all nine Sunflower Coast fields.", goal: 9, category: .fields),
        RibbonDefinition(key: .orchardKeeper, title: "Orchard Keeper", detail: "Sow all nine Orchard Rows fields.", goal: 9, category: .fields),
        RibbonDefinition(key: .linenWeaver, title: "Linen Weaver", detail: "Sow all nine Linen Valley fields.", goal: 9, category: .fields),
        RibbonDefinition(key: .crownBearer, title: "Crown Bearer", detail: "Sow all seventy-two fields.", goal: 72, category: .fields),
        RibbonDefinition(key: .meadowPerfect, title: "Meadow Perfect", detail: "Three stars on every Meadow Rise field.", goal: 9, category: .fields),
        RibbonDefinition(key: .stillWaters, title: "Still Waters", detail: "Three stars on every Lakeside Strips field.", goal: 9, category: .fields),
        RibbonDefinition(key: .fiftyStars, title: "Fifty Stars", detail: "Collect fifty ribbon stars.", goal: 50, category: .fields),
        RibbonDefinition(key: .hundredStars, title: "Hundred Stars", detail: "Collect one hundred ribbon stars.", goal: 100, category: .fields),
        RibbonDefinition(key: .starField, title: "Star Field", detail: "Collect two hundred ribbon stars.", goal: 200, category: .fields),
        RibbonDefinition(key: .goldenTouch, title: "Golden Touch", detail: "Sow twenty-five golden plots.", goal: 25, category: .skill),
        RibbonDefinition(key: .goldRush, title: "Gold Rush", detail: "Sow every golden plot in a single field.", goal: 1, category: .skill),
        RibbonDefinition(key: .sunriseSower, title: "Sunrise Sower", detail: "Finish your first Daily Sowing.", goal: 1, category: .daily),
        RibbonDefinition(key: .threeSuns, title: "Three Suns", detail: "Keep a three-day Daily Sowing streak.", goal: 3, category: .daily),
        RibbonDefinition(key: .weekOfSuns, title: "Week of Suns", detail: "Keep a seven-day Daily Sowing streak.", goal: 7, category: .daily),
        RibbonDefinition(key: .monthOfSuns, title: "Month of Suns", detail: "Keep a thirty-day Daily Sowing streak.", goal: 30, category: .daily),
        RibbonDefinition(key: .almanacOfDays, title: "Almanac of Days", detail: "Finish twenty Daily Sowings.", goal: 20, category: .daily),
        RibbonDefinition(key: .furrowHand, title: "Furrow Hand", detail: "Reach farmer rank 5.", goal: 5, category: .collection),
        RibbonDefinition(key: .sailMaster, title: "Sail Master", detail: "Reach farmer rank 10.", goal: 10, category: .collection),
        RibbonDefinition(key: .millLegend, title: "Mill Legend", detail: "Reach farmer rank 20.", goal: 20, category: .collection),
        RibbonDefinition(key: .paintedSails, title: "Painted Sails", detail: "Unlock five mill paints.", goal: 5, category: .collection),
        RibbonDefinition(key: .fullHopper, title: "Full Hopper", detail: "Sow fields with ten different seed varieties.", goal: 10, category: .collection),
        RibbonDefinition(key: .everyPodCounts, title: "Every Pod Counts", detail: "Sow a field where every pod you threw sowed a plot.", goal: 1, category: .skill),
        RibbonDefinition(key: .bigBloom, title: "Big Bloom", detail: "Score 10,000 in a single field.", goal: 1, category: .skill),
        RibbonDefinition(key: .longSeason, title: "Long Season", detail: "Finish one hundred runs.", goal: 100, category: .collection)
    ]

    static func definition(_ key: String?) -> RibbonDefinition? {
        all.first { $0.key.rawValue == key }
    }
}
