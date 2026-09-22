import SpriteKit

extension SKColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

/// Scene palette — mirrors design-tokens.css.
enum SceneColor {
    static let ink = SKColor(hex: 0x0E2350)
    static let blue700 = SKColor(hex: 0x1763DE)
    static let blue100 = SKColor(hex: 0xD6E8FF)
    static let sun500 = SKColor(hex: 0xFFC01F)
    static let sun300 = SKColor(hex: 0xFFDE6A)
    static let linen = SKColor(hex: 0xFFF6E4)
    static let leaf = SKColor(hex: 0x2F8F5B)
    static let stitchRed = SKColor(hex: 0xD9342B)
    static let fieldFar = SKColor(hex: 0xF0B324)
    static let fieldLight = SKColor(hex: 0xFFD873)
    static let furrow = SKColor(hex: 0xF0A70F)
    static let soil = SKColor(hex: 0xA9762F)
    static let soilLine = SKColor(hex: 0x7A4A05, alpha: 0.55)
    static let road = SKColor(hex: 0x8FA6C6)
    static let stoneGrey = SKColor(hex: 0xB9C7DC)
    static let shadow = SKColor(hex: 0x0E2350, alpha: 0.26)
}
