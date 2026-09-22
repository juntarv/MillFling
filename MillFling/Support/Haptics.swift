import UIKit

/// Tactile feedback, gated on PreferenceEntity.hapticsOn. No audio anywhere in the game.
final class Haptics {
    static let shared = Haptics()
    var enabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()

    func tap() { guard enabled else { return }; light.impactOccurred() }
    func release() { guard enabled else { return }; medium.impactOccurred(intensity: 0.8) }
    func burst() { guard enabled else { return }; rigid.impactOccurred() }
    func sow() { guard enabled else { return }; light.impactOccurred(intensity: 0.9) }
    func loss() { guard enabled else { return }; notify.notificationOccurred(.warning) }
    func success() { guard enabled else { return }; notify.notificationOccurred(.success) }
    func failure() { guard enabled else { return }; notify.notificationOccurred(.error) }
}
