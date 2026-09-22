import SpriteKit

/// Drifting chaff dashes that make the wind readable in the sky.
final class ChaffField {
    private var dashes: [SKSpriteNode] = []
    private var speeds: [CGFloat] = []
    private var bounds = CGRect.zero

    init(count: Int, parent: SKNode) {
        for i in 0..<count {
            let d = SKSpriteNode(color: SceneColor.linen, size: CGSize(width: 18, height: 3))
            d.alpha = 0.55
            parent.addChild(d)
            dashes.append(d)
            speeds.append(0.7 + 0.6 * CGFloat((i * 7) % 5) / 4)
        }
    }

    func layout(in rect: CGRect, unit: CGFloat) {
        bounds = rect
        for (i, d) in dashes.enumerated() {
            d.size = CGSize(width: (12 + CGFloat(i % 3) * 5) * unit, height: 3 * unit)
            let fx = CGFloat((i * 37) % 100) / 100
            let fy = CGFloat((i * 61) % 100) / 100
            d.position = CGPoint(x: rect.minX + rect.width * fx, y: rect.minY + rect.height * fy)
        }
    }

    func update(dt: CGFloat, wind: CGFloat, unit: CGFloat) {
        guard bounds.width > 0 else { return }
        let base = (wind == 0 ? 0.15 : wind) * 34 * unit
        for i in 0..<dashes.count {
            let d = dashes[i]
            d.position.x += base * speeds[i] * dt
            if d.position.x > bounds.maxX + 20 { d.position.x = bounds.minX - 20 }
            if d.position.x < bounds.minX - 20 { d.position.x = bounds.maxX + 20 }
            d.alpha = wind == 0 ? 0.25 : 0.6
        }
    }
}
