import SwiftUI
import UIKit

// MARK: - Images

/// Design art rendered with its original colours.
struct Art: View {
    let name: String
    init(_ name: String) { self.name = name }

    var body: some View {
        Image(name)
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
    }
}

extension UIImage {
    static func exists(_ name: String) -> Bool { UIImage(named: name) != nil }
}

/// Full-bleed painted background: GeometryReader + aspect fill + clipped, with a palette wash.
struct ArtBackdrop: View {
    let image: String
    var wash: Double = 0.18
    var vignette = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Palette.blue950, Palette.blue900, Palette.blue700, Palette.blue500],
                               startPoint: .top, endPoint: .bottom)
                if UIImage.exists(image) {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                LinearGradient(colors: [Palette.blue950.opacity(wash * 2.2), Palette.blue900.opacity(wash), .clear],
                               startPoint: .top, endPoint: .center)
                if vignette {
                    RadialGradient(colors: [.clear, Palette.blue950.opacity(0.35)], center: .center,
                                   startRadius: geo.size.width * 0.45, endRadius: geo.size.height * 0.75)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Text

struct MicroLabel: View {
    let text: String
    var color: Color = Palette.ink
    var size: CGFloat = Typo.microSize
    /// Allow wrapping for long tags on compact widths.
    var lines: Int = 1
    var tracking: CGFloat? = nil

    var body: some View {
        Text(text.uppercased())
            .font(Typo.heavy(size))
            .tracking(tracking ?? size * 0.2)
            .foregroundColor(color)
            .lineLimit(lines)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: lines > 1)
    }
}

extension View {
    /// Double shadow for any text that must sit directly on art.
    func readableOnArt() -> some View {
        shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Surfaces

/// Embroidered linen card: gradient, navy outline, stitched inset line, painted-wood hard shadow.
struct LinenCard<Content: View>: View {
    var padding: CGFloat = Space.s2
    var radius: CGFloat = Radius.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinenSurface(radius: radius))
    }
}

struct LinenSurface: View {
    var radius: CGFloat = Radius.md
    var textured = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [Palette.linen, Palette.linenFoot], startPoint: .top, endPoint: .bottom))
            if textured && UIImage.exists("tex_linen_canvas") {
                Image("tex_linen_canvas")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.35)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            }
            RoundedRectangle(cornerRadius: max(4, radius - 6), style: .continuous)
                .strokeBorder(Palette.ink.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .padding(5)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Palette.ink, lineWidth: 3)
        }
        .compositingGroup()
        .shadow(color: Palette.ink.opacity(0.45), radius: 0, x: 0, y: 6)
        .shadow(color: Palette.blue950.opacity(0.32), radius: 14, x: 0, y: 12)
    }
}

/// Solid navy behind the status bar, then the running cross-stitch band just below the safe-area inset.
/// Keeps carrier, time and battery readable on every device (notch or not).
struct TopStitchBand: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                LinearGradient(colors: [Palette.blue950, Palette.blue900], startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.safeAreaInsets.top)
                StitchBand()
                Spacer(minLength: 0)
            }
            .ignoresSafeArea(edges: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Cross-stitch band pinned to the top of every screen; the stitches run slowly when motion is on.
struct StitchBand: View {
    @Environment(\.motionEnabled) private var motion
    @State private var run = false

    var body: some View {
        GeometryReader { geo in
            stitches
                .frame(width: geo.size.width + 32)
                .offset(x: run ? -16 : 0)
        }
        .frame(height: 14)
        .clipped()
        .background(Palette.blue950)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard motion else { return }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) { run = true }
        }
    }

    private var stitches: some View {
        Canvas { ctx, size in
            let step: CGFloat = 8
            var x: CGFloat = -size.height
            var i = 0
            while x < size.width + size.height {
                var a = Path()
                a.move(to: CGPoint(x: x, y: size.height))
                a.addLine(to: CGPoint(x: x + size.height, y: 0))
                ctx.stroke(a, with: .color(Palette.sun500), lineWidth: 3.2)
                var b = Path()
                b.move(to: CGPoint(x: x + 4, y: 0))
                b.addLine(to: CGPoint(x: x + 4 + size.height, y: size.height))
                ctx.stroke(b, with: .color(i % 2 == 0 ? Palette.stitchRed : Palette.sun600), lineWidth: 3.2)
                x += step
                i += 1
            }
        }
    }
}

struct DashedRule: View {
    var color: Color = Palette.stitchRed
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 1))
                p.addLine(to: CGPoint(x: geo.size.width, y: 1))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
        }
        .frame(height: 2)
    }
}

struct StripedBar: View {
    let value: Double
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2).fill(Palette.barBed)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LinearGradient(stops: stripeStops, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
                RoundedRectangle(cornerRadius: height / 2).strokeBorder(Palette.ink, lineWidth: 2)
            }
        }
        .frame(height: height)
    }

    private var stripeStops: [Gradient.Stop] {
        var stops: [Gradient.Stop] = []
        let n = 24
        for i in 0..<n {
            let c = i % 2 == 0 ? Palette.sun500 : Palette.furrow
            stops.append(.init(color: c, location: Double(i) / Double(n)))
            stops.append(.init(color: c, location: Double(i + 1) / Double(n) - 0.0001))
        }
        return stops
    }
}

struct SkyPill: View {
    let text: String
    var body: some View {
        MicroLabel(text: text, color: Palette.linen)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Palette.blue950.opacity(0.66)))
            .overlay(Capsule().strokeBorder(Palette.linen.opacity(0.5), lineWidth: 2))
    }
}

// MARK: - Button styles

/// Primary: sunflower plank with a painted underside that compresses when pressed.
struct PlankButtonStyle: ButtonStyle {
    var fontSize: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Typo.heavy(fontSize))
            .tracking(1)
            .foregroundColor(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, Space.s3)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.plankUnder)
                        .offset(y: pressed ? 3 : 7)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xFFD873), Palette.sun500, Palette.sun600],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.ink, lineWidth: 3)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Palette.ink.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .padding(6)
                }
            )
            .pressEffect(pressed, scale: 0.98, sink: 4)
    }
}

/// Secondary: cobalt plate.
struct BluePlateButtonStyle: ButtonStyle {
    var fontSize: CGFloat = Typo.microSize

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Typo.heavy(fontSize))
            .tracking(fontSize * 0.2)
            .textCase(.uppercase)
            .foregroundColor(Palette.linen)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, Space.s2)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.blue950)
                        .offset(y: pressed ? 2 : 6)
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.blue700, Palette.blue900], startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(Palette.ink, lineWidth: 3)
                }
            )
            .pressEffect(pressed, scale: 0.98, sink: 4)
    }
}

/// Destructive red plate (Reset progress).
struct RedPlateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Typo.heavy(13))
            .tracking(2.6)
            .textCase(.uppercase)
            .foregroundColor(Palette.linen)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.redUnder).offset(y: pressed ? 2 : 6)
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.stitchRed)
                    RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.ink, lineWidth: 3)
                }
            )
            .pressEffect(pressed, scale: 0.98, sink: 4)
    }
}

/// Scene objects (crate, basket, map board, rosette): squash on press.
struct ArtPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.05 : 0)
            .pressEffect(configuration.isPressed, scale: 0.93)
    }
}

/// Linen square plate with a navy glyph — back and pause.
struct LinenIconButton: View {
    let systemName: String
    var size: CGFloat = 52
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .black))
                .foregroundColor(Palette.ink)
                .frame(width: size, height: size)
                .background(LinenSurface(radius: 14))
        }
        .buttonStyle(ArtPressStyle())
        .frame(minWidth: 44, minHeight: 44)
    }
}

/// Label on the Ideogram cobalt plate used under each Mill Hill object.
struct PlateLabel: View {
    let text: String
    var width: CGFloat

    var body: some View {
        ZStack {
            if UIImage.exists("btn_secondary") {
                Image("btn_secondary").resizable().renderingMode(.original)
            } else {
                RoundedRectangle(cornerRadius: 10).fill(Palette.blue700)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink, lineWidth: 2.5))
            }
            MicroLabel(text: text, color: Palette.linen, size: max(9, width * 0.085))
                .padding(.horizontal, width * 0.1)
                .readableOnArt()
        }
        .frame(width: width, height: width * 0.36)
    }
}

// MARK: - Toggle

struct FolkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            Haptics.shared.tap()
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Space.s2) {
                configuration.label
                Spacer(minLength: Space.s1)
                ToggleKnob(isOn: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
        .frame(minHeight: 44)
    }
}

private struct ToggleKnob: View {
    let isOn: Bool
    @Environment(\.motionEnabled) private var motion

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(isOn ? Palette.sun500 : Color(hex: 0xC7D6EC))
            Capsule().strokeBorder(Palette.ink, lineWidth: 3)
            Circle().fill(Palette.linen)
                .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2))
                .frame(width: 26, height: 26)
                .padding(4)
        }
        .frame(width: 60, height: 36)
        .shadow(color: Palette.ink.opacity(0.35), radius: 0, x: 0, y: 3)
        .animation(motion ? .spring(response: 0.3, dampingFraction: 0.62) : nil, value: isOn)
        .accessibilityHidden(true)
    }
}

// MARK: - Rosettes, seeds, windmill

struct Rosette: View {
    let earned: Bool
    var size: CGFloat = 62
    var hero = false

    var body: some View {
        Art(hero ? "ribbon_badge_hero" : (earned ? "ribbon_badge" : "ribbon_badge_locked"))
            .frame(width: size, height: size * 1.15)
    }
}

struct SeedArt: View {
    let key: String
    var size: CGFloat = 48
    var locked = false

    var body: some View {
        Art("seed_\(key)")
            .frame(width: size, height: size)
            .saturation(locked ? 0 : 1)
            .opacity(locked ? 0.55 : 1)
    }
}

/// The mill composed from the harvested tower and sail cross, so the sails can turn and take a paint.
struct WindmillView: View {
    let towerWidth: CGFloat
    var spinning = true
    var period: Double = 14
    var paint: Color = Palette.sun500
    @Environment(\.motionEnabled) private var motion
    @State private var angle: Double = 16

    var body: some View {
        let sails = towerWidth * 248 / 216
        let towerHeight = towerWidth * 717 / 516
        let lift = sails / 2 - towerWidth * 48 / 216
        ZStack(alignment: .top) {
            Art("mill_tower")
                .frame(width: towerWidth, height: towerHeight)
                .offset(y: lift)
            PaintedSails(paint: paint)
                .frame(width: sails, height: sails)
                .rotationEffect(.degrees(angle))
        }
        .frame(width: sails, height: lift + towerHeight, alignment: .top)
        .onAppear {
            guard spinning && motion else { return }
            withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) { angle = 16 - 360 }
        }
    }
}

/// Sail cross = a tintable cloth layer under the harvested line art.
struct PaintedSails: View {
    var paint: Color = Palette.sun500

    var body: some View {
        ZStack {
            Image("mill_sails_fill")
                .resizable()
                .renderingMode(.template)
                .interpolation(.high)
                .scaledToFit()
                .foregroundColor(paint)
            Art("mill_sails_lines")
        }
    }
}

extension MillPaint {
    var color: Color { Color(hex: hex) }
}

/// Folk segmented control: plank for the active segment, linen for the rest.
struct StitchSegments<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let active = option.0 == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = option.0 }
                } label: {
                    MicroLabel(text: option.1, color: active ? Palette.ink : Palette.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            ZStack {
                                if active {
                                    RoundedRectangle(cornerRadius: 10).fill(Palette.plankUnder).offset(y: 3)
                                    RoundedRectangle(cornerRadius: 10).fill(Palette.sun500)
                                    RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink, lineWidth: 2.5)
                                }
                            }
                        )
                }
                .buttonStyle(ArtPressStyle())
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(5)
        .background(LinenSurface(radius: 14))
    }
}

/// Illustrated empty / completed state card used across the product.
struct EdgeStateCard<Action: View>: View {
    let art: String
    let title: String
    let message: String
    @ViewBuilder var action: Action

    var body: some View {
        LinenCard(padding: Space.s3) {
            VStack(spacing: 12) {
                Art(art).frame(width: 96, height: 96).bob(4, period: 2.2)
                Text(title)
                    .font(Typo.heavy(22))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(Typo.medium(15))
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                action
            }
            .frame(maxWidth: .infinity)
        }
        .entrance(2)
    }
}

/// Small read-only stat tile used in briefings, the Farm Book and run details.
struct StatWell: View {
    let value: String
    let label: String
    var size: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            RollingText(text: value)
                .font(Typo.thin(size))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            MicroLabel(text: label, color: Palette.inkSoft, size: 9, tracking: 0.9)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.25), lineWidth: 2))
        .accessibilityElement(children: .combine)
    }
}

/// Miniature of a field's plot grid (read-only) for briefings and the ledger.
struct FieldPreview: View {
    let field: FieldDefinition
    /// Thumbnail mode: hairline gaps, no glyphs — reads as a tiny field instead of a dot grid.
    var compact = false

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = compact ? 1 : 3
            let cellW = (geo.size.width - gap * CGFloat(field.cols - 1)) / CGFloat(field.cols)
            let cellH = (geo.size.height - gap * CGFloat(field.rows - 1)) / CGFloat(field.rows)
            ZStack(alignment: .topLeading) {
                ForEach(0..<field.layout.count, id: \.self) { i in
                    let r = i / field.cols
                    let c = i % field.cols
                    RoundedRectangle(cornerRadius: compact ? 1 : 3)
                        .fill(color(field.layout[i]))
                        .overlay(RoundedRectangle(cornerRadius: compact ? 1 : 3).strokeBorder(Palette.ink.opacity(compact ? 0.5 : 1),
                                                                                             lineWidth: compact ? 0.5 : 1.5))
                        .overlay(marker(field.layout[i]).font(.system(size: min(cellW, cellH) * 0.42, weight: .black)).opacity(compact ? 0 : 1))
                        .frame(width: cellW, height: cellH)
                        .offset(x: CGFloat(c) * (cellW + gap), y: CGFloat(r) * (cellH + gap))
                }
            }
        }
        .accessibilityLabel("\(field.rows) by \(field.cols) field, \(field.sowableCount) sowable plots")
    }

    private func color(_ kind: PlotKind) -> Color {
        switch kind {
        case .soil: return Color(hex: 0xA9762F)
        case .pond: return Palette.blue700
        case .stone: return Color(hex: 0xB9C7DC)
        case .road: return Color(hex: 0x8FA6C6)
        case .golden: return Palette.sun300
        }
    }

    @ViewBuilder
    private func marker(_ kind: PlotKind) -> some View {
        switch kind {
        case .golden: Image(systemName: "star.fill").foregroundColor(Palette.ink)
        case .pond: Image(systemName: "water.waves").foregroundColor(Palette.blue100)
        default: EmptyView()
        }
    }
}
