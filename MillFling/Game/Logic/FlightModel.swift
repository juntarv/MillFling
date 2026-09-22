import CoreGraphics
import Foundation

/// 2.5D flight on a ground plane: every flyer has a ground position (gx, gy) and an altitude z.
/// It is drawn at (gx, gy + z) and its shadow at (gx, gy). Pure maths, no SpriteKit.
struct FlightState: Equatable {
    var gx: CGFloat
    var gy: CGFloat
    var z: CGFloat
    var vx: CGFloat
    var vy: CGFloat          // ground-plane velocity (negative = toward the viewer)
    var vz: CGFloat
    var gravity: CGFloat
    var drift: CGFloat

    var screen: CGPoint { CGPoint(x: gx, y: gy + z) }
    var ground: CGPoint { CGPoint(x: gx, y: gy) }

    mutating func step(dt: CGFloat, windAccel: CGFloat) {
        vx += windAccel * drift * dt
        gx += vx * dt
        gy += vy * dt
        vz -= gravity * dt
        z += vz * dt
    }
}

struct FlightTuning: Equatable {
    /// Horizontal and vertical scene units: 1 at the 390 x 844 reference.
    let unitX: CGFloat
    let unitY: CGFloat
    let throwSpeedX: CGFloat
    let throwSpeedZ: CGFloat
    let forwardSpeed: CGFloat
    let gravity: CGFloat
    let windAccelPerUnit: CGFloat
    let burstKeep: CGFloat
    let burstPop: CGFloat
    let spreadX: CGFloat
    let spreadY: CGFloat

    /// `travelDepth` is the ground distance from the mill base to the nearest row;
    /// `lobHeight` is the hub height above the mill base, so a smaller mill still reaches the nearest row.
    init(unitX: CGFloat, unitY: CGFloat, travelDepth: CGFloat, throwScale: Double, lobHeight: CGFloat = 165) {
        self.unitX = unitX
        self.unitY = unitY
        throwSpeedX = 360 * unitX * CGFloat(throwScale)
        throwSpeedZ = 360 * unitY * CGFloat(throwScale)
        gravity = 900 * unitY
        // time of a straight-up lob from the hub back to the ground sets how fast pods travel into the field
        let lift = 360 * unitY * CGFloat(throwScale)
        let lobTime = (lift + (lift * lift + 2 * gravity * max(0, lobHeight)).squareRoot()) / gravity
        forwardSpeed = travelDepth / (max(0.6, lobTime) * 1.05)
        windAccelPerUnit = 40 * unitX
        burstKeep = 0.35
        burstPop = 70 * unitY
        spreadX = 78 * unitX
        spreadY = 62 * unitY
    }
}

enum FlightModel {
    /// Tip position of a blade at `angle` (radians, 0 = east, counter-clockwise positive).
    static func tip(hub: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: hub.x + radius * cos(angle), y: hub.y + radius * sin(angle))
    }

    /// The pod leaves along the tangent of a clockwise-turning sail.
    static func launch(hub: CGPoint, radius: CGFloat, angle: CGFloat, groundY: CGFloat,
                       tuning: FlightTuning, mass: Double) -> FlightState {
        let t = tip(hub: hub, radius: radius, angle: angle)
        let dx = sin(angle)
        let dz = -cos(angle)
        return FlightState(gx: t.x, gy: groundY, z: max(0, t.y - groundY),
                           vx: tuning.throwSpeedX * dx,
                           // lobs carry deeper into the field than flat or downward throws
                           vy: -tuning.forwardSpeed * (0.6 + 0.5 * max(0, dz)),
                           vz: tuning.throwSpeedZ * dz,
                           gravity: tuning.gravity * CGFloat(0.9 + 0.2 * mass),
                           drift: 0.25)
    }

    /// Velocity of seed `i` of `count` when a pod bursts: the pod's momentum is damped and
    /// the seeds fan out around the pod's ground heading.
    static func burstSeed(from pod: FlightState, index i: Int, count: Int, variety: SeedVariety,
                          tuning: FlightTuning) -> FlightState {
        let heading = atan2(pod.vy, pod.vx)
        let fan: CGFloat = count > 1 ? (CGFloat(i) / CGFloat(count - 1) - 0.5) : 0
        let angle = heading + fan * .pi * 0.95
        let speed = CGFloat(variety.spread) * (0.85 + 0.3 * abs(fan))
        return FlightState(gx: pod.gx, gy: pod.gy, z: pod.z,
                           vx: pod.vx * tuning.burstKeep + cos(angle) * speed * tuning.spreadX,
                           vy: pod.vy * tuning.burstKeep + sin(angle) * speed * tuning.spreadY,
                           vz: min(pod.vz, 0) * 0.2 + tuning.burstPop,
                           gravity: tuning.gravity * CGFloat(0.75 + 0.5 * variety.mass),
                           drift: CGFloat(variety.drift))
    }
}
