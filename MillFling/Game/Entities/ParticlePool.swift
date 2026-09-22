import SpriteKit

/// Fixed pool of husk / leaf / splash flakes, integrated by hand — nothing is allocated per frame.
final class ParticlePool {
    private var nodes: [SKSpriteNode] = []
    private var vx: [CGFloat] = []
    private var vy: [CGFloat] = []
    private var life: [CGFloat] = []
    private var maxLife: [CGFloat] = []
    private var cursor = 0
    private var gravity: CGFloat = 600

    init(capacity: Int, texture: SKTexture, parent: SKNode) {
        nodes.reserveCapacity(capacity)
        for _ in 0..<capacity {
            let n = SKSpriteNode(texture: texture, size: CGSize(width: 9, height: 6))
            n.isHidden = true
            n.colorBlendFactor = 0
            parent.addChild(n)
            nodes.append(n)
            vx.append(0); vy.append(0); life.append(0); maxLife.append(1)
        }
    }

    func setScale(unit: CGFloat) {
        gravity = 620 * unit
        for n in nodes { n.size = CGSize(width: 9 * unit, height: 6 * unit) }
    }

    /// Emits `count` flakes from `point` with a deterministic fan (no RNG needed).
    func emit(at point: CGPoint, count: Int, speed: CGFloat, color: SKColor?, lift: CGFloat) {
        guard !nodes.isEmpty else { return }
        for i in 0..<count {
            let n = nodes[cursor]
            let angle = CGFloat(i) / CGFloat(max(1, count)) * .pi * 2 + CGFloat(cursor) * 0.37
            let s = speed * (0.6 + 0.4 * abs(sin(CGFloat(cursor) * 1.7)))
            vx[cursor] = cos(angle) * s
            vy[cursor] = sin(angle) * s * 0.7 + lift
            life[cursor] = 0.55 + 0.25 * abs(cos(CGFloat(cursor)))
            maxLife[cursor] = life[cursor]
            n.position = point
            n.zRotation = angle
            n.alpha = 1
            n.setScale(1)
            if let color {
                n.color = color
                n.colorBlendFactor = 0.85
            } else {
                n.colorBlendFactor = 0
            }
            n.isHidden = false
            cursor = (cursor + 1) % nodes.count
        }
    }

    func update(dt: CGFloat) {
        for i in 0..<nodes.count where life[i] > 0 {
            life[i] -= dt
            let n = nodes[i]
            if life[i] <= 0 {
                n.isHidden = true
                continue
            }
            vy[i] -= gravity * dt
            n.position.x += vx[i] * dt
            n.position.y += vy[i] * dt
            n.zRotation += 6 * dt
            n.alpha = life[i] / maxLife[i]
        }
    }

    func clear() {
        for i in 0..<nodes.count {
            life[i] = 0
            nodes[i].isHidden = true
        }
    }
}
