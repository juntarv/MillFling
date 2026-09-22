import SpriteKit

/// A hay cart rolling back and forth along the road row. Seeds landing on it are lost.
final class CartNode: SKSpriteNode {
    private(set) var isActive = false
    var minX: CGFloat = 0
    var maxX: CGFloat = 0
    var speedX: CGFloat = 0
    var groundHalfSize = CGSize.zero

    func activate(y: CGFloat, minX: CGFloat, maxX: CGFloat, speed: CGFloat, startX: CGFloat) {
        self.minX = minX
        self.maxX = maxX
        speedX = speed
        position = CGPoint(x: startX, y: y)
        isActive = true
        isHidden = false
    }

    func deactivate() {
        isActive = false
        isHidden = true
        position = FlyerNode.parkPoint
    }

    func step(dt: CGFloat) {
        guard isActive else { return }
        position.x += speedX * dt
        if position.x > maxX { position.x = maxX; speedX = -abs(speedX) }
        if position.x < minX { position.x = minX; speedX = abs(speedX) }
        xScale = speedX >= 0 ? abs(xScale) : -abs(xScale)
    }

    func covers(_ p: CGPoint) -> Bool {
        guard isActive else { return false }
        return abs(p.x - position.x) <= groundHalfSize.width && abs(p.y - (position.y - size.height * 0.3)) <= groundHalfSize.height
    }
}
