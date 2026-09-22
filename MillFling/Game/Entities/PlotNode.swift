import SpriteKit

/// One field plot drawn as a perspective trapezoid with its decoration.
final class PlotNode: SKShapeNode {
    let index: Int
    let kind: PlotKind
    private(set) var isSown = false
    private let sprout: SKSpriteNode
    private var furrows: SKShapeNode?

    init(index: Int, kind: PlotKind, quad: [CGPoint], unit: CGFloat,
         sproutTexture: SKTexture, stoneTexture: SKTexture) {
        self.index = index
        self.kind = kind
        let cx = quad.map(\.x).reduce(0, +) / 4
        let cy = quad.map(\.y).reduce(0, +) / 4
        let width = quad[2].x - quad[3].x
        let height = quad[0].y - quad[3].y
        sprout = SKSpriteNode(texture: sproutTexture,
                              size: CGSize(width: min(width, height) * 0.62, height: min(width, height) * 0.72))
        super.init()

        let path = CGMutablePath()
        path.addLines(between: quad)
        path.closeSubpath()
        self.path = path
        lineWidth = 2.6 * unit
        strokeColor = SceneColor.ink
        lineJoin = .round
        isAntialiased = true

        let local = { (p: CGPoint) in CGPoint(x: p.x, y: p.y) }
        switch kind {
        case .soil:
            fillColor = SceneColor.soil
            let lines = CGMutablePath()
            for f in [0.34, 0.66] as [CGFloat] {
                let y = quad[3].y + height * f
                lines.move(to: local(CGPoint(x: cx - width * 0.32, y: y)))
                lines.addLine(to: local(CGPoint(x: cx + width * 0.32, y: y)))
            }
            let node = SKShapeNode(path: lines)
            node.strokeColor = SceneColor.soilLine
            node.lineWidth = 2.4 * unit
            node.lineCap = .round
            addChild(node)
            furrows = node
        case .pond:
            fillColor = SceneColor.blue700
            let waves = CGMutablePath()
            for f in [0.35, 0.68] as [CGFloat] {
                let y = quad[3].y + height * f
                let x0 = cx - width * 0.3
                waves.move(to: CGPoint(x: x0, y: y))
                waves.addQuadCurve(to: CGPoint(x: x0 + width * 0.3, y: y), control: CGPoint(x: x0 + width * 0.15, y: y + 5 * unit))
                waves.addQuadCurve(to: CGPoint(x: x0 + width * 0.6, y: y), control: CGPoint(x: x0 + width * 0.45, y: y - 5 * unit))
            }
            let node = SKShapeNode(path: waves)
            node.strokeColor = SceneColor.blue100
            node.lineWidth = 2.4 * unit
            node.lineCap = .round
            addChild(node)
        case .stone:
            fillColor = SceneColor.soil
            let stone = SKSpriteNode(texture: stoneTexture,
                                     size: CGSize(width: min(width * 0.8, height * 1.2), height: min(height * 0.92, width * 0.66)))
            stone.position = CGPoint(x: cx, y: cy)
            addChild(stone)
        case .golden:
            fillColor = SceneColor.sun300
            let star = CGMutablePath()
            let r = min(width, height) * 0.24
            for k in 0..<10 {
                let a = CGFloat(k) * .pi / 5 + .pi / 2
                let rr = k % 2 == 0 ? r : r * 0.45
                let pt = CGPoint(x: cx + cos(a) * rr, y: cy + sin(a) * rr)
                if k == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
            }
            star.closeSubpath()
            let node = SKShapeNode(path: star)
            node.fillColor = SceneColor.linen
            node.strokeColor = SceneColor.ink
            node.lineWidth = 2 * unit
            addChild(node)
            furrows = node
            let rim = SKShapeNode(path: path.copy(dashingWithPhase: 0, lengths: [5 * unit, 5 * unit]))
            rim.strokeColor = SceneColor.stitchRed
            rim.lineWidth = 2 * unit
            rim.setScale(1)
            addChild(rim)
        case .road:
            fillColor = SceneColor.road
            let dash = CGMutablePath()
            dash.move(to: CGPoint(x: cx - width * 0.38, y: cy))
            dash.addLine(to: CGPoint(x: cx + width * 0.38, y: cy))
            let node = SKShapeNode(path: dash.copy(dashingWithPhase: 0, lengths: [8 * unit, 7 * unit]))
            node.strokeColor = SceneColor.linen
            node.lineWidth = 2.4 * unit
            addChild(node)
        }

        sprout.position = CGPoint(x: cx, y: cy + height * 0.04)
        sprout.isHidden = true
        addChild(sprout)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func sow(animated pop: SKAction?) {
        guard kind.isSowable, !isSown else { return }
        isSown = true
        fillColor = kind == .golden ? SceneColor.fieldFar : SceneColor.sun500
        furrows?.isHidden = true
        sprout.isHidden = false
        if let pop {
            sprout.setScale(0.1)
            sprout.run(pop)
        } else {
            sprout.setScale(1)
        }
    }
}
