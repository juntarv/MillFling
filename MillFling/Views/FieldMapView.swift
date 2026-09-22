import SwiftUI

/// 72 fields along a winding path, eight regions separated by star gates. Field 1 sits at the bottom.
struct FieldMapView: View {
    @EnvironmentObject private var store: FarmStore
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \FieldProgressEntity.fieldIndex, ascending: true)])
    private var progress: FetchedResults<FieldProgressEntity>

    let onBack: () -> Void
    let onPlay: (Int) -> Void
    let onAlmanac: () -> Void
    let onRegion: (RegionKey) -> Void
    let onGuide: () -> Void
    var initialBriefing: Int? = nil

    @State private var shaking: Int?
    @State private var notice: String?
    @State private var briefing: Int?

    private let spacing: CGFloat = 92
    private let gateHeight: CGFloat = 96
    private let topPad: CGFloat = 90
    private let bottomPad: CGFloat = 90
    /// Extra room under the current node so its SOW NEXT ribbon clears the next node's ring.
    private let currentGap: CGFloat = 44

    var body: some View {
        let _ = store.revision
        let current = store.currentFieldIndex
        let currentRegion = FieldCatalog.field(current).region
        let totalStars = progress.reduce(0) { $0 + Int($1.stars) }
        let sownCount = progress.filter { $0.stars > 0 }.count
        let summaries = store.regionSummaries()

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_field_rows", wash: 0.2)
            AmbientMotes(count: 18).ignoresSafeArea()

            VStack(spacing: Space.s1) {
            header(region: currentRegion, sown: sownCount, stars: totalStars)
                .entrance(0)
                .background(
                    // backing for the header + chip row so the map scrolls in beneath a surface
                    LinearGradient(colors: [Palette.blue950.opacity(0.7), Palette.blue950.opacity(0.45), Palette.blue950.opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                        .padding(.bottom, -Space.s3)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                )
            GeometryReader { geo in
                let width = geo.size.width
                let height = contentHeight
                ScrollViewReader { reader in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            trail(width: width)
                            ForEach(Region.all) { region in
                                if region.order > 0 {
                                    Button { onRegion(region.key) } label: {
                                        RegionGate(region: region, unlocked: totalStars >= region.starGate, stars: totalStars,
                                                   summary: summaries.first { $0.region.key == region.key })
                                    }
                                    .buttonStyle(ArtPressStyle())
                                    .accessibilityLabel("\(region.name) region details")
                                        .frame(width: min(width - 40, 340))
                                        .position(x: width / 2, y: gateY(region: region))
                                }
                            }
                            ForEach(0..<FieldCatalog.count, id: \.self) { i in
                                node(i, current: current)
                                    .entrance(i % 6)
                                    .position(point(i, width: width))
                            }
                            scrollAnchors
                                .allowsHitTesting(false)
                            if !store.hasPlayed {
                                SkyPill(text: "Start here")
                                    .position(x: point(0, width: width).x, y: point(0, width: width).y - 66)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(width: width, height: height)
                    }
                    .onAppear {
                        if let initialBriefing { briefing = initialBriefing }
                        for delay in [0.05, 0.4] {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                reader.scrollTo(FieldMapView.anchorID(current), anchor: .center)
                            }
                        }
                    }
                }
            }
            .clipped()
            // soft top edge: content scrolling past the chips fades out instead of being hard-cut
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(stops: [.init(color: .clear, location: 0),
                                           .init(color: .clear, location: 0.4),
                                           .init(color: .black, location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 64)
                    Color.black
                }
            )
            }

            if let notice {
                VStack {
                    Spacer()
                    LinenCard(padding: Space.s2) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill").foregroundColor(Palette.stitchRed)
                            Text(notice)
                                .font(Typo.medium(15))
                                .foregroundColor(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if let briefing {
                FieldBriefingView(fieldIndex: briefing,
                                  onClose: { self.briefing = nil },
                                  onSow: onPlay,
                                  onAlmanac: onAlmanac,
                                  onGuide: onGuide)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            TopStitchBand()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: notice)
        .animation(.easeInOut(duration: 0.22), value: briefing)
    }

    // MARK: layout

    static func anchorID(_ index: Int) -> String { "field-node-\(index)" }

    /// Invisible bands stacked top-to-bottom, one per field, centred on each node — reliable scroll targets.
    private var scrollAnchors: some View {
        let ys = (0..<FieldCatalog.count).map { contentHeight - yFromBottom($0) }
        return VStack(spacing: 0) {
            ForEach((0..<FieldCatalog.count).reversed(), id: \.self) { i in
                let top = i == FieldCatalog.count - 1 ? 0 : (ys[i] + ys[i + 1]) / 2
                let bottom = i == 0 ? contentHeight : (ys[i] + ys[i - 1]) / 2
                Color.clear
                    .frame(width: 1, height: max(1, bottom - top))
                    .id(FieldMapView.anchorID(i))
            }
        }
    }

    private var contentHeight: CGFloat {
        topPad + bottomPad + CGFloat(FieldCatalog.count - 1) * spacing + CGFloat(Region.all.count - 1) * gateHeight + currentGap
    }

    /// The node that carries the SOW NEXT ribbon (read from the already-fetched progress rows).
    private var mapCurrent: Int {
        if let open = progress.first(where: { $0.isUnlocked && $0.stars == 0 }) { return Int(open.fieldIndex) }
        return Int(progress.last(where: { $0.isUnlocked })?.fieldIndex ?? 0)
    }

    private func yFromBottom(_ i: Int) -> CGFloat {
        let gatesBelow = CGFloat(i / 9)
        let current = mapCurrent
        let gap = (current > 0 && i >= current) ? currentGap : 0
        return bottomPad + CGFloat(i) * spacing + gatesBelow * gateHeight + gap
    }

    private func point(_ i: Int, width: CGFloat) -> CGPoint {
        let x = width * (0.5 + 0.28 * sin(CGFloat(i) * 1.05 + 0.4))
        return CGPoint(x: x, y: contentHeight - yFromBottom(i))
    }

    /// Gates hang half a step above the last node of the previous region, so any extra room
    /// opened under a current node stays between the gate and that node.
    private func gateY(region: Region) -> CGFloat {
        let first = region.fields.lowerBound - 1
        return contentHeight - (yFromBottom(first - 1) + spacing * 0.5 + gateHeight * 0.5) - 6
    }

    private func trail(width: CGFloat) -> some View {
        let pts = (0..<FieldCatalog.count).map { point($0, width: width) }
        let path = Path { p in
            guard let first = pts.first else { return }
            p.move(to: first)
            for i in 1..<pts.count {
                let a = pts[i - 1], b = pts[i]
                p.addCurve(to: b, control1: CGPoint(x: a.x, y: (a.y + b.y) / 2), control2: CGPoint(x: b.x, y: (a.y + b.y) / 2))
            }
        }
        return ZStack {
            path.stroke(Palette.sun100.opacity(0.92), style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))
            path.stroke(Color(hex: 0xC99A2E).opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 10]))
        }
        .allowsHitTesting(false)
    }

    // MARK: nodes

    @ViewBuilder
    private func node(_ i: Int, current: Int) -> some View {
        let entry = progress.first { Int($0.fieldIndex) == i }
        let unlocked = entry?.isUnlocked ?? (i == 0)
        let stars = Int(entry?.stars ?? 0)
        let isCurrent = i == current && unlocked
        Button {
            if unlocked {
                briefing = i
            } else {
                Haptics.shared.loss()
                withAnimation(.default) { shaking = i }
                notice = store.lockReason(field: i)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shaking = nil }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    if notice == store.lockReason(field: i) { notice = nil }
                }
            }
        } label: {
            FieldNode(number: i + 1, state: isCurrent ? .current : (unlocked ? (stars > 0 ? .sown : .open) : .locked), stars: stars)
        }
        .buttonStyle(ArtPressStyle())
        .modifier(Shake(amount: shaking == i ? 1 : 0))
        .accessibilityLabel(unlocked ? "Field \(i + 1), \(stars) stars" : "Field \(i + 1), locked")
    }

    // MARK: header

    private func header(region: Region, sown: Int, stars: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                LinenIconButton(systemName: "arrow.left", action: onBack)
                    .accessibilityLabel("Back to Mill Hill")
                Button { onRegion(region.key) } label: {
                    LinenCard(padding: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                MicroLabel(text: "Region \(region.order + 1) of \(Region.all.count) · fields \(region.fields.lowerBound)-\(region.fields.upperBound)",
                                           color: Palette.stitchRed)
                                Text(region.name)
                                    .font(Typo.heavy(22))
                                    .foregroundColor(Palette.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .padding(.leading, 4)
                            Spacer(minLength: 4)
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Palette.blue700)
                        }
                    }
                }
                .buttonStyle(ArtPressStyle())
                .accessibilityLabel("\(region.name) region details")
            }
            HStack(spacing: Space.s1) {
                HStack(spacing: 6) {
                    MicroLabel(text: sown >= FieldCatalog.count ? "All sown" : "Sown", color: Palette.linen)
                        .fixedSize()
                    RollingText(text: "\(sown)/\(FieldCatalog.count)")
                        .font(Typo.heavy(12))
                        .foregroundColor(Palette.linen)
                        .fixedSize()
                }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(LinearGradient(colors: [Palette.blue700, Palette.blue900], startPoint: .top, endPoint: .bottom)))
                    .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: 2.5))
                HStack(spacing: 6) {
                    RollingText(text: "\(stars)")
                        .font(Typo.heavy(12))
                        .foregroundColor(Palette.ink)
                        .fixedSize()
                    MicroLabel(text: "of \(FieldCatalog.count * 3) stars", color: Palette.ink)
                        .fixedSize()
                }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Palette.plankUnder).offset(y: 4)
                            RoundedRectangle(cornerRadius: 10).fill(Palette.sun500)
                            RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink, lineWidth: 2.5)
                        }
                    )
            }
        }
        .padding(.horizontal, Space.s2)
        .padding(.top, Space.band + Space.s1)
    }
}

struct FieldNode: View {
    enum NodeState { case sown, open, current, locked }
    let number: Int
    let state: NodeState
    let stars: Int
    @Environment(\.motionEnabled) private var motion
    @State private var glow = false

    var body: some View {
        switch state {
        case .locked:
            ZStack(alignment: .topTrailing) {
                Circle().fill(Palette.blue700)
                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 4))
                    .overlay(Text("\(number)").font(Typo.heavy(16)).foregroundColor(Palette.blue300))
                    .frame(width: 50, height: 50)
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Palette.ink)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Palette.linen))
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.ink, lineWidth: 2))
                    .offset(x: 6, y: -4)
            }
            .frame(width: 60, height: 60)
        case .current:
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(Palette.sun100.opacity(glow ? 0.55 : 0.25)).frame(width: 92, height: 92)
                    rays
                    disc(size: 70, font: 24)
                }
                .frame(width: 92, height: 92)
                Text("SOW NEXT")
                    .font(Typo.heavy(12))
                    .tracking(1.6)
                    .foregroundColor(Palette.linen)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Rectangle().fill(Palette.stitchRed))
                    .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
            }
            .onAppear {
                guard motion else { return }
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { glow = true }
            }
        case .sown, .open:
            VStack(spacing: 3) {
                disc(size: 56, font: 18)
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        Diamond()
                            .fill(i < stars ? Palette.stitchRed : Palette.ink.opacity(0.22))
                            .overlay(Diamond().stroke(Palette.ink, lineWidth: 1.5))
                            .frame(width: 11, height: 13)
                    }
                }
            }
            .frame(minWidth: 56, minHeight: 56)
        }
    }

    private func disc(size: CGFloat, font: CGFloat) -> some View {
        ZStack {
            Circle().fill(Palette.sun500).overlay(Circle().strokeBorder(Palette.ink, lineWidth: size > 60 ? 5 : 4))
            Circle().fill(Palette.linen).overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2.5))
                .frame(width: size * 0.7, height: size * 0.7)
            Text("\(number)").font(Typo.heavy(font)).foregroundColor(Palette.ink)
        }
        .frame(width: size, height: size)
    }

    private var rays: some View {
        ForEach(0..<4, id: \.self) { i in
            Capsule().fill(Palette.ink)
                .frame(width: 4, height: 14)
                .offset(y: -44)
                .rotationEffect(.degrees(45 + Double(i) * 90))
        }
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}

/// Banner across the path where a new region begins.
private struct RegionGate: View {
    let region: Region
    let unlocked: Bool
    let stars: Int
    let summary: RegionSummary?

    private var statusLine: String {
        guard unlocked else { return "Opens at \(region.starGate) stars · you have \(stars)" }
        if let summary, summary.complete { return "Complete · \(summary.stars) of \(region.maxStars) stars" }
        if let summary, summary.sown > 0 { return "\(summary.sown)/\(region.fieldCount) sown · \(region.novelty)" }
        return "Open · \(region.novelty)"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(region.name.uppercased())
                .font(Typo.heavy(15))
                .tracking(1.6)
                .foregroundColor(Palette.linen)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            MicroLabel(text: statusLine, color: Palette.sun500, size: 10)
            MicroLabel(text: "Tap for region details", color: Palette.linen.opacity(0.8), size: 8.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Palette.blue900)
                if UIImage.exists("tex_wood_plank") {
                    Image("tex_wood_plank").resizable().aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                        .opacity(0.22)
                }
                RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink, lineWidth: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .background(RoundedRectangle(cornerRadius: 10).fill(Palette.blue950.opacity(0.6)).offset(y: 5))
        )
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(amount * .pi * 6), y: 0))
    }
}
