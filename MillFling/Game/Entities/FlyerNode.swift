import SpriteKit

/// A pooled airborne pod or seed. Moves on the ground plane with an altitude (see `FlightState`).
final class FlyerNode: SKSpriteNode {
    enum Kind { case pod, seed }

    static let parkPoint = CGPoint(x: -10_000, y: -10_000)

    let kind: Kind
    let shadow: SKShapeNode
    var flight = FlightState(gx: 0, gy: 0, z: 0, vx: 0, vy: 0, vz: 0, gravity: 0, drift: 0)
    private(set) var isActive = false
    var crowProof = false
    var spin: CGFloat = 5

    init(kind: Kind, texture: SKTexture, size: CGSize) {
        self.kind = kind
        shadow = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.9, height: size.width * 0.34))
        shadow.fillColor = SceneColor.shadow
        shadow.strokeColor = .clear
        super.init(texture: texture, color: .clear, size: size)
        let body = SKPhysicsBody(circleOfRadius: max(3, size.width * 0.42))
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.collisionBitMask = PhysicsCategory.none
        body.categoryBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
        deactivate()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func resize(_ newSize: CGSize) {
        setScale(1)
        size = newSize
        shadow.xScale = 1
        shadow.yScale = 1
    }

    func activate(_ state: FlightState, crowProof: Bool) {
        flight = state
        self.crowProof = crowProof
        isActive = true
        isHidden = false
        shadow.isHidden = false
        physicsBody?.categoryBitMask = kind == .pod ? PhysicsCategory.pod : PhysicsCategory.seed
        physicsBody?.contactTestBitMask = PhysicsCategory.crow
        syncPosition()
    }

    func deactivate() {
        isActive = false
        isHidden = true
        shadow.isHidden = true
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none
        position = FlyerNode.parkPoint
        shadow.position = FlyerNode.parkPoint
    }

    func syncPosition() {
        position = flight.screen
        shadow.position = flight.ground
        let s = max(0.35, 1 - flight.z / 420)
        shadow.setScale(s)
        shadow.alpha = s
    }
}
