import Foundation

/// SplitMix64 — tiny deterministic generator used for field layouts, crow timing
/// and the `-demoMode` script so identical seeds give identical frames.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }

    mutating func range(_ lower: Double, _ upper: Double) -> Double { lower + (upper - lower) * unit() }

    mutating func int(_ upperExclusive: Int) -> Int { upperExclusive <= 0 ? 0 : Int(next() % UInt64(upperExclusive)) }
}
