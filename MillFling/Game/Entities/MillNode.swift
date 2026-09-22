import SpriteKit

/// The windmill: a tower sprite anchored at its foot and a sail cross turning around the hub.
final class MillNode: SKNode {
    private let tower = SKSpriteNode(imageNamed: "mill_tower")
    private let sails = SKNode()
    private let sailFill = SKSpriteNode(imageNamed: "mill_sails_fill")
    private let sailLines = SKSpriteNode(imageNamed: "mill_sails_lines")
    private let groundShadow = SKShapeNode(ellipseOf: CGSize(width: 10, height: 4))
    private(set) var hubOffset: CGFloat = 0
    private(set) var podRadius: CGFloat = 0

    // Measured from the harvested art: foot at 286/300, hub at 48/300 of the tower box.
    private static let towerAspect: CGFloat = 516.0 / 717.0
    private static let footFraction: CGFloat = 14.0 / 300.0
    private static let hubAboveFoot: CGFloat = 238.0 / 216.0
    private static let sailsToTower: CGFloat = 248.0 / 216.0
    private static let podTipFraction: CGFloat = 112.0 / 248.0

    override init() {
        super.init()
        groundShadow.fillColor = SceneColor.shadow
        groundShadow.strokeColor = .clear
        addChild(groundShadow)
        tower.anchorPoint = CGPoint(x: 0.5, y: MillNode.footFraction)
        addChild(tower)
        sailFill.color = SceneColor.sun500
        sailFill.colorBlendFactor = 1
        sails.addChild(sailFill)
        sails.addChild(sailLines)
        addChild(sails)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func layout(towerWidth: CGFloat) {
        tower.size = CGSize(width: towerWidth, height: towerWidth / MillNode.towerAspect)
        hubOffset = towerWidth * MillNode.hubAboveFoot
        let diameter = towerWidth * MillNode.sailsToTower
        let sailSize = CGSize(width: diameter, height: diameter * 603 / 600)
        sailFill.size = sailSize
        sailLines.size = sailSize
        sails.position = CGPoint(x: 0, y: hubOffset)
        podRadius = diameter * MillNode.podTipFraction
        let shadowPath = CGPath(ellipseIn: CGRect(x: -towerWidth * 0.55, y: -towerWidth * 0.08,
                                                  width: towerWidth * 1.1, height: towerWidth * 0.16), transform: nil)
        groundShadow.path = shadowPath
    }

    func setSailAngle(_ angle: CGFloat) { sails.zRotation = angle }

    func setPaint(_ color: SKColor) {
        sailFill.color = color
    }
}
