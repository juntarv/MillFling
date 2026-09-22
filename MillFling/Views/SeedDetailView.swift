import SwiftUI

/// One seed variety in depth: lore, an animated flight profile, stats, your numbers and best fields.
struct SeedDetailView: View {
    @EnvironmentObject private var store: FarmStore
    let seedKey: String
    let onBack: () -> Void
    let onBriefing: (Int) -> Void

    var body: some View {
        let _ = store.revision
        let variety = SeedCatalog.variety(seedKey)
        let entity = store.seedEntities().first { $0.key == seedKey }
        let unlocked = entity?.isUnlocked ?? (variety.unlockField == 0)
        let inHopper = store.selectedSeed.key == seedKey
        let runs = store.runs(forSeed: seedKey)

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_almanac", wash: 0.3)
            AmbientMotes(count: 14, color: Palette.sun100).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "Seed \(variety.sortIndex + 1) of \(SeedCatalog.all.count) · \(variety.traitLine)",
                                 title: variety.name, onBack: onBack) {
                        SeedArt(key: seedKey, size: 36, locked: !unlocked).sway(6, period: 2.2, anchor: .bottom)
                    }
                    .entrance(0)

                    hero(variety, unlocked: unlocked, inHopper: inHopper)
                        .entrance(1)

                    SectionHeader(title: "How it flies", trailing: "wind →")
                    LinenCard(padding: Space.s2) {
                        VStack(alignment: .leading, spacing: Space.s1 + 4) {
                            FlightProfileView(seed: variety)
                                .frame(height: 150)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.blue100.opacity(0.6)))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            ChartLegend(items: [(variety.name, ChartInk.series), ("Rye, for comparison", ChartInk.muted)])
                            statBar("Mass", variety.mass)
                            statBar("Spread", Double(variety.seedsPerBurst) / 6)
                            statBar("Drift", variety.drift)
                            statBar("Bloom", Double(75 + variety.bloomBonus) / 135)
                        }
                    }
                    .entrance(2)

                    SectionHeader(title: "Your harvest with it")
                    numbers(runs: runs, entity: entity, unlocked: unlocked)
                        .entrance(3)
                }
                .screenPadding()
            }

            TopStitchBand()
        }
    }

    // MARK: hero

    private func hero(_ variety: SeedVariety, unlocked: Bool, inHopper: Bool) -> some View {
        LinenCard(padding: Space.s3) {
            VStack(alignment: .leading, spacing: Space.s2) {
                HStack(alignment: .center, spacing: Space.s2) {
                    SeedArt(key: variety.key, size: 92, locked: !unlocked)
                        .padding(Space.s1)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Palette.sun100))
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.ink, lineWidth: 3))
                        .bob(3, period: 2)
                    VStack(alignment: .leading, spacing: 6) {
                        MicroLabel(text: "\(variety.seedsPerBurst) seeds per burst", color: Palette.stitchRed)
                        Text(variety.lore)
                            .font(Typo.medium(15))
                            .foregroundColor(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let trait = variety.trait.summary {
                    HStack(alignment: .top, spacing: Space.s1) {
                        Image(systemName: "sparkles").foregroundColor(Palette.stitchRed)
                        Text(trait)
                            .font(Typo.heavy(14))
                            .foregroundColor(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Space.s1 + 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                }
                if !unlocked {
                    HStack(spacing: Space.s1) {
                        Image(systemName: "lock.fill").foregroundColor(Palette.ink)
                        MicroLabel(text: "Sow field \(variety.unlockField) to unlock", lines: 2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.barBed))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 2.5))
                } else if inHopper {
                    HStack(spacing: Space.s1) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Palette.leaf)
                        MicroLabel(text: "In the hopper for your next run", color: Palette.leaf)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                } else {
                    Button {
                        Haptics.shared.success()
                        store.selectSeed(variety.key)
                    } label: { Text("PUT IN THE HOPPER") }
                        .buttonStyle(PlankButtonStyle(fontSize: 20))
                        .breathe(0.02)
                }
            }
        }
    }

    private func statBar(_ label: String, _ value: Double) -> some View {
        HStack(spacing: Space.s1) {
            MicroLabel(text: label, color: Palette.inkSoft)
                .frame(width: 64, alignment: .leading)
            StripedBar(value: value, height: 12)
        }
    }

    // MARK: numbers

    struct FieldBest {
        let field: Int
        let best: Int
    }

    /// Top three campaign fields by best winning score with this seed.
    static func bestFields(_ wins: [RunRecordEntity]) -> [FieldBest] {
        var best: [Int: Int] = [:]
        for run in wins where run.dailyKey == nil {
            best[Int(run.fieldIndex)] = max(best[Int(run.fieldIndex)] ?? 0, Int(run.score))
        }
        return best.sorted { $0.value > $1.value }.prefix(3).map { FieldBest(field: $0.key, best: $0.value) }
    }

    @ViewBuilder
    private func numbers(runs: [RunRecordEntity], entity: SeedEntity?, unlocked: Bool) -> some View {
        if runs.isEmpty {
            EdgeStateCard(art: "seed_\(seedKey)", title: unlocked ? "Not sown with this seed yet" : "Still in the seed catalogue",
                          message: unlocked ? "Put it in the hopper and see how it flies — its runs, plots and best fields will be kept here."
                                            : "Sow field \(SeedCatalog.variety(seedKey).unlockField) and it will arrive in the crate.") {
                EmptyView()
            }
        } else {
            let wins = runs.filter { $0.outcome == "sown" }
            let total = max(1, store.stats.totalRuns)
            let bestFields = SeedDetailView.bestFields(wins)
            LinenCard(padding: Space.s2) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    HStack(spacing: Space.s1) {
                        StatWell(value: "\(runs.count)", label: "runs", size: 22)
                        StatWell(value: Format.number(Int(entity?.plotsSown ?? 0)), label: "plots", size: 22)
                        StatWell(value: Format.number(Int(entity?.bestScore ?? 0)), label: "best", size: 22)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        MicroLabel(text: "Share of all your runs", color: Palette.inkSoft, size: 9.5)
                        StripedBar(value: Double(runs.count) / Double(total), height: 10)
                        MicroLabel(text: "\(Format.percent(Double(runs.count) / Double(total))) · \(wins.count) sown",
                                   color: Palette.inkSoft, size: 9)
                    }
                    if !bestFields.isEmpty {
                        DashedRule(color: Palette.ink.opacity(0.3))
                        MicroLabel(text: "Best fields for \(SeedCatalog.variety(seedKey).name)", color: Palette.inkSoft)
                        ForEach(bestFields, id: \.field) { entry in
                            let field = FieldCatalog.field(entry.field)
                            Button { onBriefing(entry.field) } label: {
                                HStack(spacing: Space.s2) {
                                    ZStack {
                                        Circle().fill(Palette.sun500).overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2.5))
                                        Text("\(field.number)").font(Typo.heavy(14)).foregroundColor(Palette.ink)
                                    }
                                    .frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Field \(field.number)").font(Typo.heavy(15)).foregroundColor(Palette.ink)
                                        MicroLabel(text: field.region.name, color: Palette.inkSoft, size: 9)
                                    }
                                    Spacer(minLength: 4)
                                    RollingText(text: Format.number(entry.best))
                                        .font(Typo.thin(20))
                                        .foregroundColor(Palette.ink)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(Palette.inkSoft)
                                }
                                .frame(minHeight: 48)
                            }
                            .buttonStyle(RowPressStyle())
                            .accessibilityLabel("Field \(field.number), best \(entry.best) with this seed")
                        }
                    }
                    DashedRule(color: Palette.ink.opacity(0.3))
                    MicroLabel(text: "Recent runs", color: Palette.inkSoft)
                    VStack(spacing: 4) {
                        ForEach(Array(runs.prefix(5)), id: \.objectID) { run in
                            RunLine(run: run)
                        }
                    }
                }
            }
        }
    }
}

/// Animated side view of a burst: this seed's fan (cobalt) against Rye's (slate), with wind drift.
struct FlightProfileView: View {
    let seed: SeedVariety
    @Environment(\.motionEnabled) private var motion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !motion)) { timeline in
            Canvas { ctx, size in
                let t = motion ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.6) / 2.6 : 1.0
                let ground = size.height * 0.86
                let hub = CGPoint(x: size.width * 0.1, y: size.height * 0.62)
                let burst = CGPoint(x: size.width * 0.42, y: size.height * 0.18)

                // ground and the pod's arc to the burst point
                var groundPath = Path()
                groundPath.move(to: CGPoint(x: 0, y: ground))
                groundPath.addLine(to: CGPoint(x: size.width, y: ground))
                ctx.stroke(groundPath, with: .color(ChartInk.grid), lineWidth: 1)
                var arc = Path()
                arc.move(to: hub)
                arc.addQuadCurve(to: burst, control: CGPoint(x: size.width * 0.18, y: size.height * 0.05))
                ctx.stroke(arc, with: .color(Palette.ink.opacity(0.35)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7]))

                drawFan(ctx: &ctx, size: size, burst: burst, ground: ground, variety: SeedCatalog.variety("rye"),
                        color: ChartInk.muted, progress: t, dashed: true)
                drawFan(ctx: &ctx, size: size, burst: burst, ground: ground, variety: seed,
                        color: ChartInk.series, progress: t, dashed: false)

                // mill hub
                let hubRect = CGRect(x: hub.x - 7, y: hub.y - 7, width: 14, height: 14)
                ctx.fill(Path(ellipseIn: hubRect), with: .color(Palette.linen))
                ctx.stroke(Path(ellipseIn: hubRect), with: .color(Palette.ink), lineWidth: 2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(seed.name) bursts into \(seed.seedsPerBurst) seeds; drift \(Int(seed.drift * 100)) percent, mass \(Int(seed.mass * 100)) percent")
    }

    private func drawFan(ctx: inout GraphicsContext, size: CGSize, burst: CGPoint, ground: CGFloat,
                         variety: SeedVariety, color: Color, progress: Double, dashed: Bool) {
        let count = max(1, variety.seedsPerBurst)
        let spreadWidth = size.width * 0.16 * CGFloat(variety.spread)
        let drift = size.width * 0.22 * CGFloat(variety.drift)
        let float = CGFloat(1 - variety.mass)
        for i in 0..<count {
            let fan = count > 1 ? CGFloat(i) / CGFloat(count - 1) - 0.5 : 0
            let land = CGPoint(x: burst.x + drift + fan * spreadWidth * 2, y: ground)
            let control = CGPoint(x: burst.x + fan * spreadWidth + drift * float, y: burst.y + (ground - burst.y) * 0.25)
            var trail = Path()
            trail.move(to: burst)
            trail.addQuadCurve(to: land, control: control)
            ctx.stroke(trail, with: .color(color.opacity(dashed ? 0.8 : 1)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: dashed ? [4, 5] : []))
            // a seed travelling down each trail
            let u = CGFloat(progress)
            let a = 1 - u
            let x = a * a * burst.x + 2 * a * u * control.x + u * u * land.x
            let y = a * a * burst.y + 2 * a * u * control.y + u * u * land.y
            let dot = CGRect(x: x - 5, y: y - 4, width: 10, height: 8)
            ctx.fill(Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)), with: .color(Palette.blue100))
            ctx.fill(Path(ellipseIn: dot), with: .color(color))
        }
    }
}
