import SpriteKit

/// A crow crossing the sky band. Seeds (or the pod) it touches are lost.
final class CrowNode: SKSpriteNode {
    private(set) var isActive = false
    var velocityX: CGFloat = 0
    var baseY: CGFloat = 0
    var bobPhase: CGFloat = 0
    var respawnTimer: CGFloat = 0

    init(texture: SKTexture, size: CGSize) {
        super.init(texture: texture, color: .white, size: size)
        colorBlendFactor = 0
        let body = SKPhysicsBody(circleOfRadius: size.height * 0.42)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.none
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
        deactivate()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func activate(x: CGFloat, y: CGFloat, velocityX: CGFloat, phase: CGFloat) {
        self.velocityX = velocityX
        baseY = y
        bobPhase = phase
        position = CGPoint(x: x, y: y)
        xScale = velocityX >= 0 ? abs(xScale) : -abs(xScale)
        isActive = true
        isHidden = false
        physicsBody?.categoryBitMask = PhysicsCategory.crow
        physicsBody?.contactTestBitMask = PhysicsCategory.flyer
    }

    func deactivate() {
        isActive = false
        isHidden = true
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none
        position = FlyerNode.parkPoint
    }
}
