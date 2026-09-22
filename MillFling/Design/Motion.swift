import SwiftUI

// MARK: - Motion preference

private struct MotionEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Mirrors PreferenceEntity.animationsOn. Every decorative animation checks it.
    var motionEnabled: Bool {
        get { self[MotionEnabledKey.self] }
        set { self[MotionEnabledKey.self] = newValue }
    }
}

enum MotionCurve {
    static let press = Animation.spring(response: 0.26, dampingFraction: 0.58)
    static let entrance = Animation.spring(response: 0.55, dampingFraction: 0.82)
    static let roll = Animation.easeOut(duration: 0.9)
}

// MARK: - Entrances

/// Staggered rise-in used for the sections of every screen.
private struct Entrance: ViewModifier {
    let index: Int
    @Environment(\.motionEnabled) private var motion
    @State private var shown = false

    func body(content: Content) -> some View {
        let visible = shown || !motion
        return content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 22)
            .scaleEffect(visible ? 1 : 0.97, anchor: .top)
            .onAppear {
                guard motion, !shown else { return }
                withAnimation(MotionCurve.entrance.delay(0.04 + Double(min(index, 9)) * 0.06)) { shown = true }
            }
    }
}

// MARK: - Ambient loops

private struct Sway: ViewModifier {
    let degrees: Double
    let period: Double
    let anchor: UnitPoint
    let phase: Double
    @Environment(\.motionEnabled) private var motion
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(motion ? (on ? degrees : -degrees) : 0), anchor: anchor)
            .onAppear {
                guard motion else { return }
                withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true).delay(phase)) { on = true }
            }
    }
}

private struct Bob: ViewModifier {
    let amount: CGFloat
    let period: Double
    let phase: Double
    @Environment(\.motionEnabled) private var motion
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .offset(y: motion ? (on ? -amount : amount) : 0)
            .onAppear {
                guard motion else { return }
                withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true).delay(phase)) { on = true }
            }
    }
}

private struct Breathe: ViewModifier {
    let amount: CGFloat
    @Environment(\.motionEnabled) private var motion
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(motion && on ? 1 + amount : 1)
            .onAppear {
                guard motion else { return }
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

private struct Spin: ViewModifier {
    let period: Double
    @Environment(\.motionEnabled) private var motion
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(motion && on ? 360 : 0))
            .onAppear {
                guard motion else { return }
                withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) { on = true }
            }
    }
}

extension View {
    /// Staggered entrance; `index` orders sections top to bottom.
    func entrance(_ index: Int = 0) -> some View { modifier(Entrance(index: index)) }
    /// Pinned-ribbon style swing around an anchor.
    func sway(_ degrees: Double = 3, period: Double = 2.4, anchor: UnitPoint = .top, phase: Double = 0) -> some View {
        modifier(Sway(degrees: degrees, period: period, anchor: anchor, phase: phase))
    }
    /// Gentle float up and down.
    func bob(_ amount: CGFloat = 4, period: Double = 1.8, phase: Double = 0) -> some View {
        modifier(Bob(amount: amount, period: period, phase: phase))
    }
    /// Slow scale pulse for primary actions.
    func breathe(_ amount: CGFloat = 0.025) -> some View { modifier(Breathe(amount: amount)) }
    /// Continuous rotation (rays, loaders).
    func spin(period: Double = 12) -> some View { modifier(Spin(period: period)) }
    /// Spring press + haptic for any custom tappable surface.
    func pressEffect(_ pressed: Bool, scale: CGFloat = 0.96, sink: CGFloat = 0) -> some View {
        modifier(PressEffect(pressed: pressed, scale: scale, sink: sink))
    }
    /// Shared 8-pt screen rhythm: 16 pt gutters, 8 pt top, 48 pt bottom breathing room.
    func screenPadding() -> some View {
        padding(.horizontal, Space.s2)
            .padding(.top, Space.band + Space.s1)
            .padding(.bottom, Space.s5)
    }
}

/// Spring scale + sink on press, with a light haptic on touch-down. Honours the motion preference.
struct PressEffect: ViewModifier {
    let pressed: Bool
    var scale: CGFloat = 0.96
    var sink: CGFloat = 0
    @Environment(\.motionEnabled) private var motion

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? scale : 1)
            .offset(y: pressed ? sink : 0)
            .animation(motion ? MotionCurve.press : nil, value: pressed)
            .onChange(of: pressed) { down in
                if down { Haptics.shared.tap() }
            }
    }
}

// MARK: - Drifting motes

/// Pollen and chaff drifting across a screen — the ambient layer behind content.
struct AmbientMotes: View {
    var count: Int = 16
    var color: Color = Palette.sun100
    @Environment(\.motionEnabled) private var motion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !motion)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let seed = Double(i) * 12.9898
                    let speed = 10 + (sin(seed) + 1) * 9
                    let baseX = (sin(seed * 3.1) + 1) / 2
                    let baseY = (cos(seed * 1.7) + 1) / 2
                    var x = (baseX * Double(size.width) + t * speed).truncatingRemainder(dividingBy: Double(size.width) + 40) - 20
                    if x < -20 { x += Double(size.width) + 40 }
                    let y = baseY * Double(size.height) + sin(t * 0.8 + seed) * 12
                    let r = 1.6 + (cos(seed) + 1) * 1.4
                    let rect = CGRect(x: x, y: y, width: r * (i % 3 == 0 ? 4 : 2), height: r)
                    ctx.opacity = 0.35 + 0.35 * (sin(t * 1.3 + seed) + 1) / 2
                    ctx.fill(Path(roundedRect: rect, cornerRadius: r / 2), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Rolling numerals

/// Parses the first integer in a label ("x18", "4 820", "76%", "12/40") so it can roll up from zero.
enum NumberRoll {
    static func render(_ text: String, fraction: Double) -> String {
        guard fraction < 1 else { return text }
        let chars = Array(text)
        guard let start = chars.firstIndex(where: { $0.isNumber }) else { return text }
        var end = start
        var digits = ""
        var grouped = false
        while end < chars.count {
            let c = chars[end]
            if c.isNumber {
                digits.append(c)
            } else if (c == "\u{2009}" || c == "," || c == " ") && end + 1 < chars.count && chars[end + 1].isNumber {
                grouped = true
            } else {
                break
            }
            end += 1
        }
        guard let value = Int(digits) else { return text }
        let scaled = Int((Double(value) * max(0, fraction)).rounded())
        let formatted = grouped ? Format.number(scaled) : "\(scaled)"
        return String(chars[..<start]) + formatted + String(chars[end...])
    }
}

/// Text whose number rolls up from zero on appear and ticks over (numericText) when it changes.
struct RollingText: View {
    let text: String
    @Environment(\.motionEnabled) private var motion
    @State private var settled = false

    var body: some View {
        Text(NumberRoll.render(text, fraction: settled || !motion ? 1 : 0))
            .monospacedDigit()
            .contentTransition(.numericText())
            .onAppear {
                guard motion, !settled else { return }
                withAnimation(MotionCurve.roll.delay(0.15)) { settled = true }
            }
            .animation(motion ? .spring(response: 0.4, dampingFraction: 0.8) : nil, value: text)
    }
}

// MARK: - Section header

/// Micro label in a navy pill + running stitch rule: the section divider on decorated backgrounds.
struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: Space.s1) {
            MicroLabel(text: title, color: Palette.linen)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Palette.blue950.opacity(0.72)))
                .overlay(Capsule().strokeBorder(Palette.linen.opacity(0.45), lineWidth: 1.5))
                .layoutPriority(2)
            Rectangle()
                .fill(Palette.sun500)
                .frame(minWidth: 8, maxWidth: .infinity, minHeight: 3, maxHeight: 3)
                .mask(HStack(spacing: 5) { ForEach(0..<48, id: \.self) { _ in Rectangle().frame(width: 6) } })
                .layoutPriority(0)
            if let trailing {
                MicroLabel(text: trailing, color: Palette.linen, size: 10)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Palette.blue950.opacity(0.72)))
                    .layoutPriority(1)
            }
        }
        .padding(.top, Space.s1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Pressable wrapper for plain tappable rows: spring + haptic without re-styling the content.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .pressEffect(configuration.isPressed, scale: 0.98)
            .brightness(configuration.isPressed ? -0.03 : 0)
    }
}
