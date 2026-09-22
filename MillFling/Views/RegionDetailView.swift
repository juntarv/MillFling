import SwiftUI

/// One region in depth: completion ring, stars, clear bonus, its nine fields and your records there.
struct RegionDetailView: View {
    @EnvironmentObject private var store: FarmStore
    let regionKey: RegionKey
    let onBack: () -> Void
    let onPlay: (Int) -> Void
    let onAlmanac: () -> Void
    let onGuide: () -> Void

    @State private var briefing: Int?
    @State private var notice: String?

    static func backdrop(for key: RegionKey) -> String {
        switch key {
        case .meadow: return "bg_menu"
        case .lakeside: return "bg_onboarding"
        case .terraced: return "bg_field_rows"
        case .storm: return "bg_game"
        case .coast: return "bg_splash"
        case .orchard: return "bg_settings"
        case .linen: return "bg_sky_noon"
        case .crown: return "bg_ribbons"
        }
    }

    var body: some View {
        let _ = store.revision
        let region = Region.all.first { $0.key == regionKey } ?? Region.all[0]
        let summary = store.regionSummaries().first { $0.region.key == regionKey }
        let fields = region.fields.map { $0 - 1 }
        let runs = store.runs(inRegion: regionKey)

        ZStack(alignment: .top) {
            ArtBackdrop(image: RegionDetailView.backdrop(for: regionKey), wash: 0.3)
            AmbientMotes(count: 12).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "Region \(region.order + 1) of \(Region.all.count) · fields \(region.fields.lowerBound)-\(region.fields.upperBound)",
                                 title: region.name, onBack: onBack) {
                        Image(systemName: summary?.complete == true ? "checkmark.seal.fill" : (summary?.unlocked == true ? "leaf.fill" : "lock.fill"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(summary?.complete == true ? Palette.leaf : Palette.sun600)
                            .sway(6, period: 2.2, anchor: .bottom)
                    }
                    .entrance(0)

                    heroCard(region: region, summary: summary)
                        .entrance(1)

                    if summary?.unlocked == true {
                        SectionHeader(title: "The nine fields", trailing: "\(summary?.sown ?? 0)/\(region.fieldCount)")
                        LinenCard(padding: Space.s2) {
                            VStack(spacing: 0) {
                                if (summary?.sown ?? 0) == 0 {
                                    HStack(spacing: Space.s1) {
                                        Image(systemName: "sparkles").foregroundColor(Palette.sun600)
                                        Text("Nothing sown here yet — field \(region.fields.lowerBound) is waiting for you.")
                                            .font(Typo.medium(14))
                                            .foregroundColor(Palette.inkSoft)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.bottom, Space.s1)
                                }
                                ForEach(Array(fields.enumerated()), id: \.element) { index, fieldIndex in
                                    fieldRow(fieldIndex)
                                        .entrance(2 + index)
                                    if index < fields.count - 1 { DashedRule(color: Palette.ink.opacity(0.2)) }
                                }
                            }
                        }

                        SectionHeader(title: "Your records here")
                        records(region: region, runs: runs, summary: summary)
                            .entrance(4)
                    } else {
                        EdgeStateCard(art: "rosette_ribbon", title: "Still behind the gate",
                                      message: "\(region.name) opens at \(region.starGate) stars. You have \(store.totalStars) — replay earlier fields for three-star harvests to get there.") {
                            Button("Back to the map", action: onBack).buttonStyle(BluePlateButtonStyle())
                        }
                    }
                }
                .screenPadding()
            }

            if let notice {
                VStack {
                    Spacer()
                    LinenCard(padding: Space.s2) {
                        HStack(spacing: Space.s1) {
                            Image(systemName: "lock.fill").foregroundColor(Palette.stitchRed)
                            Text(notice)
                                .font(Typo.medium(15))
                                .foregroundColor(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, Space.s3)
                    .padding(.bottom, Space.s3)
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
        .animation(.easeInOut(duration: 0.22), value: briefing)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: notice)
    }

    // MARK: hero

    private func heroCard(region: Region, summary: RegionSummary?) -> some View {
        let sown = summary?.sown ?? 0
        let fraction = Double(sown) / Double(region.fieldCount)
        return LinenCard(padding: Space.s3) {
            VStack(alignment: .leading, spacing: Space.s2) {
                HStack(spacing: Space.s3) {
                    ZStack {
                        Circle().stroke(Palette.barBed, lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(Palette.sun500, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .strokeBorder(Palette.stitchRed, style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                            .padding(-10)
                            .spin(period: 24)
                        VStack(spacing: 0) {
                            RollingText(text: "\(sown)/\(region.fieldCount)")
                                .font(Typo.thin(30))
                                .foregroundColor(Palette.ink)
                            MicroLabel(text: "sown", color: Palette.inkSoft, size: 9)
                        }
                    }
                    .frame(width: 104, height: 104)
                    .padding(10)
                    VStack(alignment: .leading, spacing: Space.s1) {
                        Text(region.blurb)
                            .font(Typo.medium(15))
                            .foregroundColor(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)).foregroundColor(Palette.stitchRed)
                            MicroLabel(text: region.novelty, color: Palette.stitchRed, size: 9.5, lines: 2, tracking: 1.2)
                        }
                    }
                }
                HStack(spacing: Space.s1) {
                    StatWell(value: "\(summary?.stars ?? 0)/\(region.maxStars)", label: "stars", size: 22)
                    StatWell(value: "\(summary?.threeStars ?? 0)", label: "three-star", size: 22)
                    StatWell(value: "+\(region.clearBonus)", label: summary?.complete == true ? "paid" : "bonus", size: 22)
                }
                if region.starGate > 0 {
                    MicroLabel(text: "Gate: \(region.starGate) stars", color: Palette.inkSoft, size: 9.5)
                }
            }
        }
    }

    // MARK: field rows

    @ViewBuilder
    private func fieldRow(_ index: Int) -> some View {
        let field = FieldCatalog.field(index)
        let progress = store.progress(field: index)
        let unlocked = progress?.isUnlocked ?? false
        let stars = Int(progress?.stars ?? 0)
        Button {
            if unlocked {
                briefing = index
            } else {
                Haptics.shared.loss()
                notice = store.lockReason(field: index)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    if notice == store.lockReason(field: index) { notice = nil }
                }
            }
        } label: {
            HStack(spacing: Space.s2) {
                ZStack {
                    Circle().fill(unlocked ? Palette.sun500 : Palette.blue700)
                        .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 3))
                    Text("\(field.number)")
                        .font(Typo.heavy(15))
                        .foregroundColor(unlocked ? Palette.ink : Palette.blue300)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Field \(field.number)")
                        .font(Typo.heavy(15))
                        .foregroundColor(unlocked ? Palette.ink : Palette.inkSoft)
                    MicroLabel(text: field.hazardLines.prefix(2).joined(separator: " · ").isEmpty ? "open soil"
                                                                                                    : field.hazardLines.prefix(2).joined(separator: " · "),
                               color: Palette.inkSoft, size: 9, lines: 2, tracking: 0.8)
                    if unlocked {
                        StarDiamonds(stars: stars, size: 9)
                    }
                }
                Spacer(minLength: 4)
                FieldPreview(field: field, compact: true)
                    .frame(width: 58, height: CGFloat(field.rows) * 8)
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xFFD873)))
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Palette.ink, lineWidth: 1.5))
                    .opacity(unlocked ? 1 : 0.4)
                VStack(alignment: .trailing, spacing: 2) {
                    if let progress, progress.bestScore > 0 {
                        RollingText(text: Format.number(Int(progress.bestScore)))
                            .font(Typo.thin(18))
                            .foregroundColor(Palette.ink)
                        MicroLabel(text: "best", color: Palette.inkSoft, size: 8.5)
                    } else {
                        Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(unlocked ? Palette.ink : Palette.lockedArt)
                    }
                }
                .frame(width: 58, alignment: .trailing)
            }
            .padding(.vertical, Space.s1)
        }
        .buttonStyle(RowPressStyle())
        .accessibilityLabel(unlocked ? "Field \(field.number), \(stars) stars" : "Field \(field.number), locked")
    }

    // MARK: records

    private func records(region: Region, runs: [RunRecordEntity], summary: RegionSummary?) -> some View {
        let bestTotal = region.fields.reduce(0) { $0 + Int(store.progress(field: $1 - 1)?.bestScore ?? 0) }
        let attempts = region.fields.reduce(0) { $0 + Int(store.progress(field: $1 - 1)?.attempts ?? 0) }
        var counts: [String: Int] = [:]
        for run in runs { counts[run.seedKey ?? "rye", default: 0] += 1 }
        let favourite = counts.max { $0.value < $1.value }?.key
        let wins = runs.filter { $0.outcome == "sown" }.count
        return Group {
            if runs.isEmpty {
                EdgeStateCard(art: "crate_seeds", title: "No runs here yet",
                              message: "Your scores, tries and favourite seed for \(region.name) will be kept here once you sow your first field.") {
                    EmptyView()
                }
            } else {
                LinenCard(padding: Space.s2) {
                    VStack(alignment: .leading, spacing: Space.s2) {
                        HStack(spacing: Space.s1) {
                            StatWell(value: Format.number(bestTotal), label: "best total", size: 20)
                            StatWell(value: "\(attempts)", label: "tries", size: 20)
                            StatWell(value: "\(wins)/\(runs.count)", label: "sown", size: 20)
                        }
                        if let favourite {
                            HStack(spacing: Space.s2) {
                                SeedArt(key: favourite, size: 36).bob(2, period: 1.8)
                                VStack(alignment: .leading, spacing: 2) {
                                    MicroLabel(text: "Favourite seed here", color: Palette.inkSoft, size: 9.5)
                                    Text("\(SeedCatalog.variety(favourite).name) · \(counts[favourite] ?? 0) runs")
                                        .font(Typo.heavy(15))
                                        .foregroundColor(Palette.ink)
                                }
                                Spacer()
                            }
                            .padding(Space.s1)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                        }
                        if let last = runs.first {
                            MicroLabel(text: "Last played \(Format.relative(last.createdAt ?? Date())) · field \(last.fieldIndex + 1)",
                                       color: Palette.inkSoft, size: 9.5)
                        }
                    }
                }
            }
        }
    }
}
