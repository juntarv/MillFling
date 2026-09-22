import Foundation

/// The single source of truth for every collision / contact bitmask in the game.
enum PhysicsCategory {
    static let none: UInt32 = 0
    static let pod: UInt32 = 1 << 0
    static let seed: UInt32 = 1 << 1
    static let crow: UInt32 = 1 << 2
    static let cart: UInt32 = 1 << 3

    static let flyer: UInt32 = pod | seed
    static let all: UInt32 = UInt32.max
}

/// Fixed render layers — never improvise zPosition values.
enum SceneLayer {
    static let background: CGFloat = -100
    static let entities: CGFloat = 0
    static let effects: CGFloat = 50
    static let hud: CGFloat = 100
}
