import Foundation

/// The run's state machine. Transitions are validated in one place: `GameViewModel.transition(to:)`.
enum GameState: Equatable {
    case ready      // scene loaded, waiting for the first frame
    case playing
    case paused
    case sown       // quota met — Harvest Report
    case fallow     // pods ran out — Harvest Report (fallow)

    var isFinished: Bool { self == .sown || self == .fallow }

    func canMove(to next: GameState) -> Bool {
        switch (self, next) {
        case (.ready, .playing), (.ready, .ready): return true
        case (.playing, .paused), (.playing, .sown), (.playing, .fallow), (.playing, .ready): return true
        case (.paused, .playing), (.paused, .ready): return true
        case (.sown, .ready), (.fallow, .ready): return true
        default: return false
        }
    }
}

/// Throw lifecycle inside the scene (a mechanic detail, not the game state).
enum ThrowPhase: Equatable {
    case reloading
    case onSail
    case podFlying
    case seedsFalling
    case halted
}

enum LossReason: Equatable {
    case outside, water, stone, road, cart, crow
}
