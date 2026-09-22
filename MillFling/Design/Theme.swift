import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Colour tokens — derived 1:1 from design-tokens.css.
enum Palette {
    // Dominant: cobalt sky
    static let blue950 = Color(hex: 0x061F5C)
    static let blue900 = Color(hex: 0x0B3C9E)
    static let blue700 = Color(hex: 0x1763DE)
    static let blue500 = Color(hex: 0x3D86F0)
    static let blue300 = Color(hex: 0x8FC0FF)
    static let blue100 = Color(hex: 0xD6E8FF)
    // Accent: sunflower
    static let sun600 = Color(hex: 0xF09A0C)
    static let sun500 = Color(hex: 0xFFC01F)
    static let sun300 = Color(hex: 0xFFDE6A)
    static let sun100 = Color(hex: 0xFFF0BE)
    // Folk supporting
    static let linen = Color(hex: 0xFFF6E4)
    static let linen2 = Color(hex: 0xF3E2BF)
    static let ink = Color(hex: 0x0E2350)
    static let inkSoft = Color(hex: 0x3C5688)
    static let stitchRed = Color(hex: 0xD9342B)
    static let leaf = Color(hex: 0x2F8F5B)
    static let soil = Color(hex: 0x6B4A2A)
    // Derived art tones used by the mockups
    static let linenFoot = Color(hex: 0xFBEDD3)
    static let plankUnder = Color(hex: 0xA8650A)
    static let wood = Color(hex: 0x8B5E2A)
    static let barBed = Color(hex: 0xE6D3AC)
    static let furrow = Color(hex: 0xF0A70F)
    static let lockedArt = Color(hex: 0x8FA6C6)
    static let redUnder = Color(hex: 0x8C1C16)
}

/// Avenir Next at the token's extreme weights only: Heavy 800, Medium 500, Ultra Light 200.
enum Typo {
    static let microSize: CGFloat = 11
    static let smallSize: CGFloat = 14
    static let bodySize: CGFloat = 18
    static let titleSize: CGFloat = 34
    static let displaySize: CGFloat = 54
    static let heroSize: CGFloat = 96

    static func heavy(_ size: CGFloat) -> Font { .custom("AvenirNext-Heavy", size: size) }
    static func medium(_ size: CGFloat) -> Font { .custom("AvenirNext-Medium", size: size) }
    static func thin(_ size: CGFloat) -> Font { .custom("AvenirNext-UltraLight", size: size) }
}

/// 8px spacing scale.
enum Space {
    static let s0: CGFloat = 4
    static let s1: CGFloat = 8
    static let s2: CGFloat = 16
    static let s3: CGFloat = 24
    static let s4: CGFloat = 32
    static let s5: CGFloat = 48
    static let s6: CGFloat = 64
    /// Height of the cross-stitch band that sits just below the status bar.
    static let band: CGFloat = 14
}

enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 18
    static let lg: CGFloat = 28
}

/// Maps the 390 x 844 mockups (safe area 47...810) onto the real safe area.
struct DesignSpace {
    static let referenceWidth: CGFloat = 390
    static let referenceTop: CGFloat = 47
    static let referenceHeight: CGFloat = 763

    let size: CGSize

    var scale: CGFloat { min(size.width / DesignSpace.referenceWidth, size.height / DesignSpace.referenceHeight) }
    func x(_ v: CGFloat) -> CGFloat { v / DesignSpace.referenceWidth * size.width }
    func y(_ v: CGFloat) -> CGFloat { (v - DesignSpace.referenceTop) / DesignSpace.referenceHeight * size.height }
    func s(_ v: CGFloat) -> CGFloat { v * scale }
}
