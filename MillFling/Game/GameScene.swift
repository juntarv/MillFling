import SpriteKit

/// Events the scene reports; `GameViewModel` owns every rule and state transition.
protocol GameSceneEvents: AnyObject {
    func sceneShouldReload() -> Bool
    func sceneDidRelease()
    func sceneDidBurst(seeds: Int, second: Bool)
    func sceneCanSecondBurst() -> Bool
    func sceneSowed(row: Int, col: Int, trueSow: Bool, pastStone: Bool, farRight: Bool, golden: Bool)
    func sceneSeedResown()
    func sceneSeedLost(_ reason: LossReason)
    func sceneThrowResolved()
    func sceneWindChanged(_ wind: Double)
}

/// The single SKScene: mill, sails, pods, seeds, plots and hazards.
final class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var events: GameSceneEvents?

    // MARK: configuration
    private var field: FieldDefinition = FieldCatalog.field(0)
    private var variety: SeedVariety = SeedCatalog.variety(nil)
    private var safeTop: CGFloat = 0
    private var safeBottom: CGFloat = 0
    private var rng = SeededRandom(seed: 7)
    private var demoThrows: [DemoThrow] = []
    private var demoIndex = 0
    private var demoBurstTimer: CGFloat = -1
    private var demoOnSailTime: CGFloat = 0
    var effectsEnabled = true

    // MARK: layers (fixed zPositions, draw order by child order)
    private let backgroundLayer = SKNode()
    private let entityLayer = SKNode()
    private let effectsLayer = SKNode()
    private let plotLayer = SKNode()
    private let cartLayer = SKNode()
    private let shadowLayer = SKNode()
    private let flyerLayer = SKNode()
    private let crowLayer = SKNode()

    // MARK: nodes
    private let cameraNode = SKCameraNode()
    private let skyNode = SKSpriteNode(imageNamed: "bg_sky_noon")
    private let farHill = SKShapeNode()
    private let midHill = SKShapeNode()
    private let groundNode = SKShapeNode()
    private let furrowBands = SKShapeNode()
    private var clouds: [SKSpriteNode] = []
    private let mill = MillNode()
    private let podOnSail = SKSpriteNode(imageNamed: "pod_game")
    private let burstFlash = SKSpriteNode(imageNamed: "pod_burst")
    private var pods: [FlyerNode] = []
    private var seeds: [FlyerNode] = []
    private var crows: [CrowNode] = []
    private var carts: [CartNode] = []
    private var plots: [PlotNode] = []
    private var particles: ParticlePool?
    private var chaff: ChaffField?

    // MARK: textures (loaded once)
    private let sproutTexture = SKTexture(imageNamed: "sprout")
    private let stoneTexture = SKTexture(imageNamed: "stone_wall")
    private let seedTexture = SKTexture(imageNamed: "seed_single")
    private let podTexture = SKTexture(imageNamed: "pod_game")

    // MARK: layout
    private(set) var geometry = FieldGeometry.empty
    private var tuning = FlightTuning(unitX: 1, unitY: 1, travelDepth: 200, throwScale: 1)
    private var unit: CGFloat = 1
    private var hub = CGPoint.zero
    private var podRadius: CGFloat = 60
    private var millBaseY: CGFloat = 0
    private var crowBand: ClosedRange<CGFloat> = 0...1

    // MARK: run state
    private var built = false
    private var running = false
    private var phase: ThrowPhase = .halted
    private var reloadTimer: CGFloat = 0
    /// Height of the SwiftUI HUD below the top safe inset (measured by GameContainerView).
    private var hudReserve: CGFloat = 200
    private var sailAngle: CGFloat = 2.3
    private var sailSpeed: CGFloat = 1.6
    private var elapsed: Double = 0
    private var lastUpdate: TimeInterval = 0
    private var currentWind: Double = 0
    private var sown: [Bool] = []

    // MARK: reusable actions (rebuilt on layout, never inside update)
    private var shakeAction = SKAction()
    private var popAction = SKAction()
    private var appearAction = SKAction()
    private let flashAction = SKAction.sequence([
        SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.05),
        SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
    ])
    private let burstAction = SKAction.group([
        SKAction.scale(to: 1.45, duration: 0.24),
        SKAction.sequence([SKAction.wait(forDuration: 0.08), SKAction.fadeOut(withDuration: 0.2)])
    ])

    // MARK: lifecycle

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(hex: 0x1763DE)
        anchorPoint = .zero
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        buildOnce()
        relayout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard built else { return }
        relayout()
    }

    private func buildOnce() {
        guard !built else { return }
        built = true
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        addChild(cameraNode)
        camera = cameraNode

        backgroundLayer.zPosition = SceneLayer.background
        entityLayer.zPosition = SceneLayer.entities
        effectsLayer.zPosition = SceneLayer.effects
        addChild(backgroundLayer)
        addChild(entityLayer)
        addChild(effectsLayer)

        backgroundLayer.addChild(skyNode)
        for i in 0..<2 {
            let c = SKSpriteNode(imageNamed: "cloud_puff")
            c.alpha = i == 0 ? 0.95 : 0.75
            backgroundLayer.addChild(c)
            clouds.append(c)
        }
        chaff = ChaffField(count: 12, parent: backgroundLayer)
        for node in [farHill, midHill, groundNode, furrowBands] {
            node.strokeColor = .clear
            backgroundLayer.addChild(node)
        }
        farHill.fillColor = SceneColor.fieldFar
        midHill.fillColor = SceneColor.sun500
        groundNode.fillColor = SceneColor.fieldLight
        furrowBands.fillColor = SceneColor.furrow.withAlphaComponent(0.5)

        for layer in [plotLayer, cartLayer] { entityLayer.addChild(layer) }
        entityLayer.addChild(mill)
        for layer in [shadowLayer, flyerLayer, crowLayer] { entityLayer.addChild(layer) }

        podOnSail.isHidden = true
        flyerLayer.addChild(podOnSail)

        for _ in 0..<2 {
            let p = FlyerNode(kind: .pod, texture: podTexture, size: CGSize(width: 30, height: 23))
            shadowLayer.addChild(p.shadow)
            flyerLayer.addChild(p)
            pods.append(p)
        }
        for _ in 0..<28 {
            let s = FlyerNode(kind: .seed, texture: seedTexture, size: CGSize(width: 15, height: 12))
            shadowLayer.addChild(s.shadow)
            flyerLayer.addChild(s)
            seeds.append(s)
        }
        let crowTexture = SKTexture(imageNamed: "crow_hazard")
        for _ in 0..<3 {
            let c = CrowNode(texture: crowTexture, size: CGSize(width: 62, height: 40))
            crowLayer.addChild(c)
            crows.append(c)
        }
        for _ in 0..<2 {
            let cart = CartNode(imageNamed: "hay_cart")
            cart.deactivate()
            cartLayer.addChild(cart)
            carts.append(cart)
        }

        particles = ParticlePool(capacity: 64, texture: SKTexture(imageNamed: "husk_flake"), parent: effectsLayer)
        burstFlash.isHidden = true
        effectsLayer.addChild(burstFlash)
    }

    // MARK: public API (called by GameViewModel)

    func setHUDReserve(_ height: CGFloat) {
        guard abs(height - hudReserve) > 1 else { return }
        hudReserve = height
        if built { relayout() }
    }

    func setSafeInsets(top: CGFloat, bottom: CGFloat) {
        guard abs(top - safeTop) > 0.5 || abs(bottom - safeBottom) > 0.5 else { return }
        safeTop = top
        safeBottom = bottom
        if built { relayout() }
    }

    func configure(field: FieldDefinition, variety: SeedVariety, demo: [DemoThrow], rngSeed: UInt64, presown: [Int]) {
        self.field = field
        self.variety = variety
        demoThrows = demo
        demoIndex = 0
        demoBurstTimer = -1
        demoOnSailTime = 0
        rng = SeededRandom(seed: rngSeed)
        elapsed = 0
        currentWind = field.wind.value(at: 0)
        sown = Array(repeating: false, count: field.rows * field.cols)
        for i in presown where i < sown.count && field.layout[i].isSowable { sown[i] = true }
        sailSpeed = CGFloat(field.sailSpeed) * (variety.trait == .steadyHand ? 0.85 : 1)
        sailAngle = demo.isEmpty ? 2.9 : CGFloat(demo[0].releaseAngle) + sailSpeed * 0.75
        buildOnce()
        for p in pods { p.deactivate() }
        for s in seeds { s.deactivate() }
        for c in crows {
            c.deactivate()
            c.respawnTimer = CGFloat(rng.range(0.8, 2.2))
        }
        for c in carts { c.deactivate() }
        particles?.clear()
        podOnSail.isHidden = true
        phase = .reloading
        reloadTimer = 0.25
        relayout()
        events?.sceneWindChanged(currentWind)
    }

    func setRunning(_ value: Bool) {
        running = value
        lastUpdate = 0
    }

    /// Stops throwing once the run is decided.
    func halt() {
        phase = .halted
        podOnSail.isHidden = true
    }

    func shake() {
        guard effectsEnabled else { return }
        cameraNode.removeAction(forKey: "shake")
        cameraNode.run(shakeAction, withKey: "shake")
    }

    var windValue: Double { currentWind }

    /// Recolours the sail cloth with the selected mill paint.
    func setPaint(hex: UInt32) {
        mill.setPaint(SKColor(hex: hex))
    }

    // MARK: layout

    private func relayout() {
        let w = size.width, h = size.height
        guard w > 10, h > 10 else { return }
        let ux = w / 390, uy = h / 844
        unit = min(ux, uy)
        cameraNode.position = CGPoint(x: w / 2, y: h / 2)

        let groundBottom = safeBottom + 14 * unit
        let fieldTop = max(groundBottom + 160 * unit, h * 0.35)
        millBaseY = fieldTop + 26 * unit
        // Scale the mill from the bottom of the HUD down: the highest sail tip (and the pod riding it)
        // must stay below the HUD on every screen size.
        let hudFloor = h - safeTop - hudReserve - 8 * unit
        let reachPerTowerWidth: CGFloat = 238.0 / 216.0 + 124.0 / 216.0
        let room = hudFloor - 16 * unit - millBaseY
        var towerWidth = 150 * unit
        if room > 0 { towerWidth = min(towerWidth, room / reachPerTowerWidth) }
        towerWidth = max(towerWidth, 84 * unit)
        mill.layout(towerWidth: towerWidth)
        mill.position = CGPoint(x: w * 0.22, y: millBaseY)
        hub = CGPoint(x: mill.position.x, y: millBaseY + mill.hubOffset)
        podRadius = mill.podRadius
        // SKSpriteNode.size is scale-aware: settle any running scale action before resizing,
        // or a relayout mid pop-in bakes the temporary scale into the base size.
        podOnSail.removeAllActions()
        podOnSail.setScale(1)
        podOnSail.size = CGSize(width: 34 * unit, height: 26 * unit)

        geometry = FieldGeometry(rows: field.rows, cols: field.cols, top: fieldTop, bottom: groundBottom,
                                 centerX: w * 0.57, farHalfWidth: w * 0.35, nearHalfWidth: w * 0.42, gap: 5 * unit)
        tuning = FlightTuning(unitX: ux, unitY: uy, travelDepth: millBaseY - groundBottom, throwScale: field.throwScale,
                              lobHeight: mill.hubOffset)
        crowBand = (millBaseY + 40 * unit)...(hub.y + podRadius * 0.7)

        // sky: aspect-fill the painted backdrop
        if let tex = skyNode.texture {
            let ts = tex.size()
            let scale = max(w / max(ts.width, 1), h / max(ts.height, 1))
            skyNode.size = CGSize(width: ts.width * scale, height: ts.height * scale)
        }
        skyNode.position = CGPoint(x: w / 2, y: h / 2)
        for (i, c) in clouds.enumerated() {
            c.size = CGSize(width: (i == 0 ? 120 : 90) * unit, height: (i == 0 ? 59 : 44) * unit)
            c.position = CGPoint(x: w * (i == 0 ? 0.74 : 0.52),
                                 y: min(hudFloor - c.size.height, i == 0 ? hub.y + 30 * unit : hub.y - 70 * unit))
        }
        chaff?.layout(in: CGRect(x: 0, y: millBaseY + 20 * unit, width: w, height: max(40, hudFloor - millBaseY - 20 * unit)), unit: unit)

        farHill.path = hillPath(width: w, baseline: millBaseY + 58 * unit, amplitude: 14 * unit, phase: 0.4)
        midHill.path = hillPath(width: w, baseline: millBaseY + 22 * unit, amplitude: 10 * unit, phase: 1.7)
        groundNode.path = CGPath(rect: CGRect(x: -20, y: -20, width: w + 40, height: fieldTop + 10 * unit + 20), transform: nil)
        let bands = CGMutablePath()
        for f in [0.18, 0.46, 0.76] as [CGFloat] {
            let y = groundBottom + (fieldTop - groundBottom) * f
            bands.addRect(CGRect(x: -20, y: y, width: w + 40, height: 12 * unit))
        }
        furrowBands.path = bands

        for p in pods { p.resize(CGSize(width: 30 * unit, height: 23 * unit)) }
        for s in seeds { s.resize(CGSize(width: 15 * unit, height: 12 * unit)) }
        for c in crows {
            let facing: CGFloat = c.xScale < 0 ? -1 : 1
            c.setScale(1)
            c.size = CGSize(width: 64 * unit, height: 43 * unit)
            c.xScale = facing
            c.physicsBody = nil
            let body = SKPhysicsBody(circleOfRadius: 17 * unit)
            body.isDynamic = true
            body.affectedByGravity = false
            body.allowsRotation = false
            body.collisionBitMask = PhysicsCategory.none
            body.categoryBitMask = c.isActive ? PhysicsCategory.crow : PhysicsCategory.none
            body.contactTestBitMask = c.isActive ? PhysicsCategory.flyer : PhysicsCategory.none
            c.physicsBody = body
        }
        burstFlash.removeAllActions()
        burstFlash.setScale(1)
        burstFlash.isHidden = true
        burstFlash.size = CGSize(width: 64 * unit, height: 64 * unit)
        particles?.setScale(unit: unit)

        shakeAction = SKAction.sequence([
            SKAction.moveBy(x: 7 * unit, y: 3 * unit, duration: 0.03),
            SKAction.moveBy(x: -12 * unit, y: -5 * unit, duration: 0.04),
            SKAction.moveBy(x: 9 * unit, y: 4 * unit, duration: 0.04),
            SKAction.moveBy(x: -4 * unit, y: -2 * unit, duration: 0.04),
            SKAction.move(to: CGPoint(x: w / 2, y: h / 2), duration: 0.03)
        ])
        popAction = SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.13), SKAction.scale(to: 1, duration: 0.1)])
        appearAction = SKAction.scale(to: 1, duration: 0.16)

        rebuildPlots()
        layoutCarts()
    }

    private func hillPath(width w: CGFloat, baseline: CGFloat, amplitude: CGFloat, phase: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -20, y: -20))
        p.addLine(to: CGPoint(x: -20, y: baseline))
        let steps = 24
        for i in 0...steps {
            let x = -20 + (w + 40) * CGFloat(i) / CGFloat(steps)
            let y = baseline + amplitude * sin(CGFloat(i) / CGFloat(steps) * .pi * 2.2 + phase)
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: w + 20, y: -20))
        p.closeSubpath()
        return p
    }

    private func rebuildPlots() {
        plotLayer.removeAllChildren()
        plots.removeAll(keepingCapacity: true)
        guard sown.count == field.rows * field.cols else { return }
        for r in 0..<field.rows {
            for c in 0..<field.cols {
                let idx = r * field.cols + c
                let node = PlotNode(index: idx, kind: field.layout[idx], quad: geometry.quad(row: r, col: c),
                                    unit: unit, sproutTexture: sproutTexture, stoneTexture: stoneTexture)
                if sown[idx] { node.sow(animated: nil) }
                plotLayer.addChild(node)
                plots.append(node)
            }
        }
    }

    private func layoutCarts() {
        let roadRows = (0..<field.rows).filter { r in
            (0..<field.cols).contains { field.kind(row: r, col: $0) == .road }
        }
        for (i, cart) in carts.enumerated() {
            guard i < field.carts, i < roadRows.count else {
                cart.deactivate()
                continue
            }
            let roadRow = roadRows[i]
            let centre = geometry.center(row: roadRow, col: 0)
            let plotSize = geometry.plotSize(row: roadRow, col: 0)
            let hw = geometry.halfWidth(atY: centre.y)
            cart.setScale(1)
            cart.size = CGSize(width: plotSize.width * 0.95, height: plotSize.width * 0.95 * 213 / 330)
            cart.groundHalfSize = CGSize(width: plotSize.width * 0.5, height: plotSize.height * 0.55)
            let y = centre.y + cart.size.height * 0.3
            let wasX = cart.isActive ? cart.position.x : geometry.centerX + hw * (i == 0 ? -0.5 : 0.4)
            cart.activate(y: y, minX: geometry.centerX - hw + plotSize.width * 0.4,
                          maxX: geometry.centerX + hw - plotSize.width * 0.4,
                          speed: (i == 0 ? 46 : -38) * unit, startX: wasX)
        }
    }

    // MARK: input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard running, demoThrows.isEmpty else { return }
        handleTap()
    }

    private func handleTap() {
        switch phase {
        case .onSail: release()
        case .podFlying: burst()
        case .seedsFalling:
            if variety.trait == .secondBurst, events?.sceneCanSecondBurst() == true { secondBurst() }
        case .reloading, .halted: break
        }
    }

    private func release() {
        guard let pod = pods.first(where: { !$0.isActive }) else { return }
        let state = FlightModel.launch(hub: hub, radius: podRadius, angle: sailAngle, groundY: millBaseY,
                                       tuning: tuning, mass: variety.mass)
        pod.activate(state, crowProof: variety.trait == .crowProof)
        pod.zRotation = sailAngle
        podOnSail.isHidden = true
        phase = .podFlying
        events?.sceneDidRelease()
    }

    private func burst() {
        guard let pod = pods.first(where: { $0.isActive }) else { return }
        let count = variety.seedsPerBurst
        var spawned = 0
        for i in 0..<count {
            guard let seed = seeds.first(where: { !$0.isActive }) else { break }
            seed.activate(FlightModel.burstSeed(from: pod.flight, index: i, count: count, variety: variety, tuning: tuning),
                          crowProof: variety.trait == .crowProof)
            spawned += 1
        }
        let at = pod.position
        pod.deactivate()
        showBurst(at: at)
        phase = .seedsFalling
        events?.sceneDidBurst(seeds: spawned, second: false)
    }

    private func secondBurst() {
        var spawned = 0
        for s in seeds where s.isActive {
            guard let extra = seeds.first(where: { !$0.isActive }) else { break }
            var copy = s.flight
            copy.vx += tuning.spreadX * 0.8
            copy.vz = max(copy.vz, tuning.burstPop * 0.6)
            s.flight.vx -= tuning.spreadX * 0.8
            extra.activate(copy, crowProof: s.crowProof)
            spawned += 1
            showBurst(at: s.position)
        }
        if spawned > 0 { events?.sceneDidBurst(seeds: spawned, second: true) }
    }

    private func showBurst(at point: CGPoint) {
        burstFlash.removeAllActions()
        burstFlash.position = point
        burstFlash.setScale(0.45)
        burstFlash.alpha = 1
        burstFlash.isHidden = false
        burstFlash.run(burstAction)
        particles?.emit(at: point, count: 10, speed: 150 * unit, color: nil, lift: 60 * unit)
    }

    // MARK: frame loop — no allocations below this line

    override func update(_ currentTime: TimeInterval) {
        let rawDt = lastUpdate == 0 ? 1.0 / 60.0 : currentTime - lastUpdate
        lastUpdate = currentTime
        guard running else { return }
        let dt = CGFloat(min(max(rawDt, 0), 1.0 / 30.0))
        elapsed += Double(dt)

        let wind = field.wind.value(at: elapsed)
        if wind != currentWind {
            currentWind = wind
            events?.sceneWindChanged(wind)
        }

        sailAngle -= sailSpeed * dt
        if sailAngle < 0 { sailAngle += .pi * 2 }
        mill.setSailAngle(sailAngle)

        switch phase {
        case .reloading:
            reloadTimer -= dt
            if reloadTimer <= 0 {
                if events?.sceneShouldReload() == true {
                    phase = .onSail
                    demoOnSailTime = 0
                    podOnSail.setScale(0.2)
                    podOnSail.isHidden = false
                    podOnSail.run(appearAction)
                } else {
                    phase = .halted
                }
            }
        case .onSail:
            podOnSail.position = FlightModel.tip(hub: hub, radius: podRadius, angle: sailAngle)
            podOnSail.zRotation = sailAngle
            runDemoRelease(dt: dt)
        case .podFlying:
            stepFlyers(pods, dt: dt)
            if !demoThrows.isEmpty && demoBurstTimer >= 0 {
                demoBurstTimer -= dt
                if demoBurstTimer < 0 { burst() }
            }
        case .seedsFalling:
            stepFlyers(seeds, dt: dt)
        case .halted:
            break
        }

        if (phase == .podFlying || phase == .seedsFalling) && !anyFlyerActive() {
            phase = .reloading
            reloadTimer = 0.35
            events?.sceneThrowResolved()
        }

        stepCrows(dt: dt)
        for c in carts { c.step(dt: dt) }
        chaff?.update(dt: dt, wind: CGFloat(currentWind), unit: unit)
        particles?.update(dt: dt)
        stepClouds(dt: dt)
    }

    private func runDemoRelease(dt: CGFloat) {
        guard !demoThrows.isEmpty else { return }
        demoOnSailTime += dt
        let plan = demoThrows[demoIndex % demoThrows.count]
        var gap = sailAngle - CGFloat(plan.releaseAngle)
        if gap < 0 { gap += .pi * 2 }
        if demoOnSailTime > 0.2 && gap < sailSpeed * dt * 1.5 {
            release()
            demoBurstTimer = CGFloat(plan.burstDelay)
            demoIndex += 1
        }
    }

    private func stepFlyers(_ list: [FlyerNode], dt: CGFloat) {
        let windAccel = CGFloat(currentWind) * tuning.windAccelPerUnit
        let w = size.width
        for f in list where f.isActive {
            f.flight.step(dt: dt, windAccel: windAccel)
            f.zRotation -= f.spin * dt
            f.syncPosition()
            if f.flight.z <= 0 {
                land(f)
            } else if f.flight.gx < -90 || f.flight.gx > w + 90 || f.flight.gy < -60 {
                f.deactivate()
                events?.sceneSeedLost(.outside)
            }
        }
    }

    private func anyFlyerActive() -> Bool {
        for p in pods where p.isActive { return true }
        for s in seeds where s.isActive { return true }
        return false
    }

    private func land(_ f: FlyerNode) {
        let p = f.flight.ground
        f.deactivate()
        for c in carts where c.covers(p) {
            c.run(flashAction)
            particles?.emit(at: p, count: 6, speed: 90 * unit, color: SceneColor.sun300, lift: 40 * unit)
            events?.sceneSeedLost(.cart)
            return
        }
        guard let hit = geometry.hitTest(p) else {
            particles?.emit(at: p, count: 5, speed: 70 * unit, color: SceneColor.fieldFar, lift: 30 * unit)
            events?.sceneSeedLost(.outside)
            return
        }
        let kind = field.layout[hit.index]
        switch kind {
        case .pond:
            particles?.emit(at: p, count: 8, speed: 110 * unit, color: SceneColor.blue100, lift: 70 * unit)
            events?.sceneSeedLost(.water)
        case .stone:
            particles?.emit(at: p, count: 6, speed: 100 * unit, color: SceneColor.stoneGrey, lift: 50 * unit)
            if hit.index < plots.count { plots[hit.index].run(flashAction) }
            events?.sceneSeedLost(.stone)
        case .road:
            particles?.emit(at: p, count: 5, speed: 80 * unit, color: SceneColor.road, lift: 30 * unit)
            events?.sceneSeedLost(.road)
        case .soil, .golden:
            if sown[hit.index] {
                events?.sceneSeedResown()
                return
            }
            sown[hit.index] = true
            let golden = kind == .golden
            if hit.index < plots.count { plots[hit.index].sow(animated: effectsEnabled ? popAction : nil) }
            particles?.emit(at: p, count: golden ? 14 : 9, speed: 120 * unit,
                            color: golden ? SceneColor.sun300 : SceneColor.leaf, lift: 90 * unit)
            if golden && effectsEnabled { showBurst(at: p) }
            let pastStone = hit.row > 0 && field.kind(row: hit.row - 1, col: hit.col) == .stone
            events?.sceneSowed(row: hit.row, col: hit.col,
                               trueSow: hit.centreDistance <= CGFloat(ScoreRules.trueSowRadius),
                               pastStone: pastStone, farRight: hit.col == field.cols - 1, golden: golden)
        }
    }

    private func stepCrows(dt: CGFloat) {
        let w = size.width
        for i in 0..<crows.count {
            let c = crows[i]
            if c.isActive {
                c.position.x += c.velocityX * dt
                c.position.y = c.baseY + sin(CGFloat(elapsed) * 5 + c.bobPhase) * 5 * unit
                if c.position.x < -80 || c.position.x > w + 80 {
                    c.deactivate()
                    c.respawnTimer = CGFloat(rng.range(1.4, 3.4))
                }
            } else if i < field.crows && phase != .halted {
                c.respawnTimer -= dt
                if c.respawnTimer <= 0 {
                    let fromLeft = rng.unit() < 0.5
                    let y = crowBand.lowerBound + (crowBand.upperBound - crowBand.lowerBound) * CGFloat(rng.unit())
                    let speed = CGFloat(rng.range(70, 115)) * unit
                    c.activate(x: fromLeft ? -60 : w + 60, y: y, velocityX: fromLeft ? speed : -speed,
                               phase: CGFloat(rng.unit()) * 6)
                }
            }
        }
    }

    private func stepClouds(dt: CGFloat) {
        let w = size.width
        let drift = (CGFloat(currentWind) * 6 + 4) * unit
        for i in 0..<clouds.count {
            let c = clouds[i]
            c.position.x += drift * (i == 0 ? 1 : 0.6) * dt
            if c.position.x > w + c.size.width { c.position.x = -c.size.width }
            if c.position.x < -c.size.width { c.position.x = w + c.size.width }
        }
    }

    // MARK: contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.node, b = contact.bodyB.node
        let crow = (a as? CrowNode) ?? (b as? CrowNode)
        let flyer = (a as? FlyerNode) ?? (b as? FlyerNode)
        guard let crow, let flyer, flyer.isActive, crow.isActive else { return }
        crow.run(flashAction)
        if flyer.crowProof {
            particles?.emit(at: crow.position, count: 4, speed: 80 * unit, color: SceneColor.ink, lift: 20 * unit)
            return
        }
        let at = flyer.position
        flyer.deactivate()
        particles?.emit(at: at, count: 7, speed: 110 * unit, color: SceneColor.ink, lift: 40 * unit)
        events?.sceneSeedLost(.crow)
    }
}
