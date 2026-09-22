import SwiftUI

/// Main menu as a scene on the hill: every control is an object standing in the field.
struct MillHillView: View {
    @EnvironmentObject private var store: FarmStore
    let onSow: (SowTarget) -> Void
    let onFields: () -> Void
    let onRibbons: () -> Void
    let onAlmanac: () -> Void
    let onSettings: () -> Void
    let onDaily: () -> Void
    let onFarmBook: () -> Void

    @Environment(\.motionEnabled) private var motion
    @State private var arrived = false

    var body: some View {
        let _ = store.revision
        let target = store.sowTarget
        let animate = motion
        let paint = store.selectedPaint.color
        let streak = store.dailyStreak
        let doneToday = store.todayCompleted

        ZStack {
            ArtBackdrop(image: "bg_menu", wash: 0.12)
            AmbientMotes(count: 20, color: Palette.linen).ignoresSafeArea()

            GeometryReader { geo in
                let L = DesignSpace(size: geo.size)
                ZStack(alignment: .topLeading) {
                    // --- scenery: mill, pod arc, sunflowers ---
                    Group {
                        WindmillView(towerWidth: L.s(186), spinning: animate, paint: paint)
                            .position(x: L.x(291), y: L.y(190) + L.s(324) / 2)

                        PodArc(animate: animate)
                            .frame(width: L.s(200), height: L.s(170))
                            .position(x: L.x(262), y: L.y(418))
                            .allowsHitTesting(false)

                        Art("sunflower_cluster")
                            .frame(width: L.s(90), height: L.s(140))
                            .position(x: L.x(318) + L.s(45), y: L.y(726) + L.s(70))
                            .allowsHitTesting(false)
                    }

                    // --- title lockup ---
                    VStack(alignment: .leading, spacing: L.s(2)) {
                        Art(UIImage.exists("logo_title") ? "logo_title" : "title_banner")
                            .frame(width: L.s(250))
                            .shadow(color: Palette.blue950.opacity(0.55), radius: 0, x: 0, y: L.s(6))
                            .shadow(color: Palette.blue950.opacity(0.4), radius: 12, x: 0, y: 10)
                        SkyPill(text: "Sow the bright fields")
                            .padding(.leading, L.s(18))
                    }
                    .rotationEffect(.degrees(-4))
                    .bob(2, period: 3.2)
                    .position(x: L.x(14) + L.s(125), y: L.y(56) + L.s(76))
                    .scaleEffect(arrived ? 1 : 0.92)
                    .opacity(arrived ? 1 : 0)

                    // --- DAILY: the embroidered sun above the mill ---
                    Button(action: onDaily) {
                        VStack(spacing: -L.s(4)) {
                            SunBadge(done: doneToday, size: L.s(78))
                            PlateLabel(text: doneToday ? "Daily · sown" : (streak > 0 ? "Daily · \(streak) days" : "Daily sowing"),
                                       width: L.s(124))
                        }
                    }
                    .buttonStyle(ArtPressStyle())
                    .entrance(1)
                    .accessibilityLabel(doneToday ? "Daily Sowing, sown today" : "Daily Sowing, \(streak) day streak")
                    .position(x: L.x(326), y: L.y(58) + L.s(62))

                    // --- scene objects ---
                    Group {
                        // RIBBONS: rosette staked in the field
                        Button(action: onRibbons) {
                            VStack(spacing: -L.s(6)) {
                                ZStack(alignment: .top) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(colors: [Color(hex: 0xA8702F), Palette.wood], startPoint: .leading, endPoint: .trailing))
                                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.ink, lineWidth: 3))
                                        .frame(width: L.s(12), height: L.s(56))
                                        .offset(y: L.s(80))
                                    Art("rosette_ribbon").frame(width: L.s(98), height: L.s(106))
                                }
                                .frame(height: L.s(118), alignment: .top)
                                PlateLabel(text: "Ribbons \(store.ribbonsEarned)/\(store.ribbonsTotal)", width: L.s(126))
                            }
                        }
                        .buttonStyle(ArtPressStyle())
                        .sway(2.5, period: 2.8, anchor: .bottom)
                        .entrance(2)
                        .accessibilityLabel("Ribbon Wall, \(store.ribbonsEarned) of \(store.ribbonsTotal) ribbons")
                        .position(x: L.x(14) + L.s(63), y: L.y(372) + L.s(80))

                        // FARM BOOK: the embroidered towel with lifetime stats
                        Button(action: onFarmBook) {
                            TowelStats(seeds: Int(store.stats.totalSeedsSown), streak: Int(store.stats.bestStreak),
                                       fields: store.fieldsSownCount, rank: store.rank.level, width: L.s(250))
                        }
                        .buttonStyle(ArtPressStyle())
                        .sway(1.2, period: 3.4, anchor: .top, phase: 0.4)
                        .entrance(3)
                        .accessibilityLabel("Farm Book, rank \(store.rank.level) \(store.rank.title)")
                        .rotationEffect(.degrees(-2))
                        .position(x: L.x(16) + L.s(125), y: L.y(522) + L.s(67))

                        // PRIMARY: the SOW sign
                        SowSign(line: signLine(target), width: L.s(262)) { onSow(target) }
                            .breathe(0.018)
                            .rotationEffect(.degrees(-3))
                            .position(x: L.x(10) + L.s(131), y: L.y(628) + L.s(62))
                            .scaleEffect(arrived ? 1 : 0.9)

                        // FIELD MAP: map board on a post
                        Button(action: onFields) {
                            VStack(spacing: -L.s(14)) {
                                Art("post_fields").frame(width: L.s(112), height: L.s(151))
                                PlateLabel(text: "Field map", width: L.s(116))
                            }
                        }
                        .buttonStyle(ArtPressStyle())
                        .entrance(4)
                        .accessibilityLabel("Field map")
                        .position(x: L.x(262) + L.s(58), y: L.y(592) + L.s(88))

                        // ALMANAC: seed crate
                        Button(action: onAlmanac) {
                            VStack(spacing: -L.s(2)) {
                                Art("crate_seeds").frame(width: L.s(100), height: L.s(76))
                                PlateLabel(text: "Almanac", width: L.s(104))
                            }
                        }
                        .buttonStyle(ArtPressStyle())
                        .entrance(5)
                        .accessibilityLabel("Seed Almanac")
                        .position(x: L.x(18) + L.s(54), y: L.y(698) + L.s(56))

                        // SETTINGS: tool basket
                        Button(action: onSettings) {
                            VStack(spacing: -L.s(8)) {
                                Art(UIImage.exists("icon_settings") ? "icon_settings" : "basket_tools")
                                    .frame(width: L.s(84), height: L.s(84))
                                PlateLabel(text: "Settings", width: L.s(98))
                            }
                        }
                        .buttonStyle(ArtPressStyle())
                        .entrance(6)
                        .accessibilityLabel("Settings")
                        .position(x: L.x(146) + L.s(50), y: L.y(696) + L.s(58))
                    }

                    // --- first run: point at the sign ---
                    if !store.hasPlayed {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(Palette.sun300)
                            SkyPill(text: "Tap the sign to sow field 1")
                        }
                        .bob(4, period: 0.8)
                        .position(x: L.x(150), y: L.y(612))
                        .allowsHitTesting(false)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.top, Space.band)

            TopStitchBand()
        }
        .onAppear {
            if motion {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) { arrived = true }
            } else {
                arrived = true
            }
        }
    }

    private func signLine(_ target: SowTarget) -> String {
        switch target {
        case .field(let index):
            let field = FieldCatalog.field(index)
            return "FIELD \(field.number) · \(field.region.name.uppercased())"
        case .gated(let region, let needed):
            return "\(needed) MORE STARS FOR \(region.uppercased())"
        case .allSown:
            return "ALL 72 SOWN · TODAY'S FIELD"
        }
    }
}

/// The primary action: a hand-painted plank on two posts with a live field line.
private struct SowSign: View {
    let line: String
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        let plateHeight = width / 3
        Button(action: action) {
            ZStack(alignment: .top) {
                HStack(spacing: width * 0.5) {
                    post
                    post
                }
                .padding(.top, plateHeight * 0.6)
                ZStack {
                    if UIImage.exists("btn_primary") {
                        Image("btn_primary").resizable().renderingMode(.original)
                            .frame(width: width, height: plateHeight)
                    } else {
                        RoundedRectangle(cornerRadius: 12).fill(Palette.sun500)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 3))
                            .frame(width: width * 0.92, height: plateHeight * 0.72)
                    }
                    Text("SOW")
                        .font(Typo.heavy(width * 0.115))
                        .tracking(3)
                        .foregroundColor(Palette.ink)
                        .shadow(color: Palette.linen.opacity(0.75), radius: 0, x: 0, y: 2)
                        .offset(y: -plateHeight * 0.1)
                    // the field line rides on a stitched linen ribbon across the plank's lower edge
                    Text(line)
                        .font(Typo.heavy(max(9, width * 0.034)))
                        .tracking(1)
                        .foregroundColor(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .frame(maxWidth: width * 0.78)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 5).fill(Palette.ink.opacity(0.35)).offset(y: 2)
                                RoundedRectangle(cornerRadius: 5).fill(Palette.linen)
                                RoundedRectangle(cornerRadius: 5).strokeBorder(Palette.ink, lineWidth: 2)
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Palette.stitchRed.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .padding(3)
                            }
                        )
                        .offset(y: plateHeight * 0.27)
                }
            }
            .frame(width: width, height: plateHeight * 1.42, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(SignPressStyle())
        .accessibilityLabel("Sow: \(line.lowercased())")
    }

    private var post: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Palette.wood)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.ink, lineWidth: 3))
            .frame(width: width * 0.055, height: width / 3 * 0.8)
    }
}

/// Dominant press: scale down + a firm haptic.
private struct SignPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { down in
                if down { Haptics.shared.release() }
            }
    }
}

/// Lifetime stats embroidered on the towel strung across the hill.
private struct TowelStats: View {
    let seeds: Int
    let streak: Int
    let fields: Int
    let rank: Int
    let width: CGFloat

    var body: some View {
        let s = width / 250
        ZStack(alignment: .top) {
            Art("rushnyk_stats").frame(width: width, height: width / 1.855)
            HStack(spacing: 0) {
                stat(Format.number(seeds), "seeds", s)
                stat("\(streak)", "streak", s)
                stat("\(fields)/\(FieldCatalog.count)", "fields", s)
            }
            .padding(.horizontal, 12 * s)
            .padding(.top, 30 * s)
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill").font(.system(size: 10 * s, weight: .black))
                MicroLabel(text: "Rank \(rank)", color: Palette.linen, size: 8.5 * s)
            }
            .foregroundColor(Palette.linen)
            .padding(.horizontal, 7 * s)
            .padding(.vertical, 4 * s)
            .background(Capsule().fill(Palette.blue700))
            .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: 2))
            .rotationEffect(.degrees(4))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .offset(x: 6 * s, y: -6 * s)
        }
        .frame(width: width, height: width / 1.855)
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String, _ s: CGFloat) -> some View {
        VStack(spacing: 3 * s) {
            RollingText(text: value)
                .font(Typo.thin(28 * s))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            MicroLabel(text: label, color: Palette.inkSoft, size: 9 * s)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A pod drifting along its dotted arc from a sail tip into the field.
private struct PodArc: View {
    let animate: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let start = CGPoint(x: w * 0.94, y: h * 0.08)
            let control = CGPoint(x: w * 0.45, y: h * 0.12)
            let end = CGPoint(x: w * 0.08, y: h * 0.9)
            ZStack {
                Path { p in
                    p.move(to: start)
                    p.addQuadCurve(to: end, control: control)
                }
                .stroke(Palette.linen.opacity(0.9), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 13]))
                if animate {
                    TimelineView(.animation) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3.2) / 3.2
                        pod(at: point(t: CGFloat(t), start, control, end), angle: t * 400)
                    }
                } else {
                    pod(at: end, angle: 28)
                }
            }
        }
    }

    private func pod(at p: CGPoint, angle: Double) -> some View {
        Art("pod_seed").frame(width: 30, height: 28).rotationEffect(.degrees(angle)).position(p)
    }

    private func point(t: CGFloat, _ a: CGPoint, _ c: CGPoint, _ b: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                       y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }
}
