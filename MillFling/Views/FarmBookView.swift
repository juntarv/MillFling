import SwiftUI
import CoreData

/// The farmer's book: rank and lifetime numbers on one tab, the ledger of every run on the other.
struct FarmBookView: View {
    enum Tab: Hashable { case overview, ledger }
    enum LedgerFilter: Hashable { case all, sown, fallow, daily }

    @EnvironmentObject private var store: FarmStore
    @FetchRequest(fetchRequest: FarmBookView.runsRequest)
    private var runs: FetchedResults<RunRecordEntity>

    let onBack: () -> Void
    let onPaints: () -> Void
    let onPlayField: (Int) -> Void
    let onDaily: () -> Void
    let onRegion: (RegionKey) -> Void
    let onGuide: () -> Void
    let onCharts: () -> Void
    let onSeed: (String) -> Void

    @State private var tab: Tab
    @State private var filter: LedgerFilter = .all
    @State private var openRun: NSManagedObjectID?

    init(startOnLedger: Bool, onBack: @escaping () -> Void, onPaints: @escaping () -> Void,
         onPlayField: @escaping (Int) -> Void, onDaily: @escaping () -> Void,
         onRegion: @escaping (RegionKey) -> Void, onGuide: @escaping () -> Void,
         onCharts: @escaping () -> Void, onSeed: @escaping (String) -> Void) {
        _tab = State(initialValue: startOnLedger ? .ledger : .overview)
        self.onBack = onBack
        self.onPaints = onPaints
        self.onPlayField = onPlayField
        self.onDaily = onDaily
        self.onRegion = onRegion
        self.onGuide = onGuide
        self.onCharts = onCharts
        self.onSeed = onSeed
    }

    static var runsRequest: NSFetchRequest<RunRecordEntity> {
        let request: NSFetchRequest<RunRecordEntity> = RunRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 300
        return request
    }

    var body: some View {
        let _ = store.revision
        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_settings", wash: 0.28)
            AmbientMotes(count: 12).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "Rank \(store.rank.level) · \(store.rank.title)", title: "Farm Book", onBack: onBack) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Palette.blue700)
                            .sway(5, period: 2.6, anchor: .bottom)
                    }
                    .entrance(0)
                    StitchSegments(options: [(Tab.overview, "Overview"), (Tab.ledger, "Ledger · \(runs.count)")], selection: $tab)
                        .padding(.top, Space.s1 - 2)
                        .entrance(1)
                    if tab == .overview { overview } else { ledger }
                }
                .screenPadding()
            }

            if let id = openRun, let run = runs.first(where: { $0.objectID == id }) {
                RunDetailView(run: run, onClose: { openRun = nil }, onReplay: {
                    openRun = nil
                    if run.dailyKey != nil { onDaily() } else { onPlayField(Int(run.fieldIndex)) }
                }, onSeed: {
                    openRun = nil
                    onSeed(run.seedKey ?? SeedCatalog.defaultKey)
                })
                .transition(.opacity)
            }

            TopStitchBand()
        }
        .animation(.easeInOut(duration: 0.22), value: openRun)
    }

    // MARK: overview

    @ViewBuilder
    private var overview: some View {
        let rank = store.rank
        let next = RankCatalog.next(after: rank)
        let bushels = Int(store.stats.bushels)
        LinenCard(padding: Space.s2) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Rosette(earned: true, size: 70, hero: true)
                        // clean linen disc over the rosette's centre diamond so the rank number reads clearly
                        Circle()
                            .fill(Palette.linen)
                            .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2))
                            .frame(width: 28, height: 28)
                            .offset(y: -9)
                        Text("\(rank.level)")
                            .font(Typo.heavy(15))
                            .foregroundColor(Palette.ink)
                            .minimumScaleFactor(0.7)
                            .frame(width: 24)
                            .offset(y: -9)
                    }
                    .sway(4, period: 2.4)
                    VStack(alignment: .leading, spacing: 3) {
                        MicroLabel(text: "Farmer rank \(rank.level) of \(RankCatalog.all.count)", color: Palette.stitchRed)
                        Text(rank.title)
                            .font(Typo.heavy(26))
                            .foregroundColor(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        RollingText(text: "\(Format.number(bushels)) bushels harvested")
                            .font(Typo.medium(14))
                            .foregroundColor(Palette.inkSoft)
                    }
                }
                StripedBar(value: store.rankProgress, height: 12)
                if let next {
                    MicroLabel(text: "\(Format.number(next.threshold - bushels)) bushels to \(next.title)", color: Palette.inkSoft)
                } else {
                    MicroLabel(text: "Top rank reached — the valley knows your name", color: Palette.leaf)
                }
                Button(action: onPaints) {
                    HStack(spacing: 10) {
                        PaintedSails(paint: store.selectedPaint.color).frame(width: 34, height: 34)
                        Text("PAINT SHED · \(store.paintEntities().filter(\.isUnlocked).count)/\(PaintCatalog.all.count)")
                    }
                }
                .buttonStyle(BluePlateButtonStyle())
                Button(action: onGuide) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.fill")
                        Text("FIELD GUIDE · \(FieldGuideCatalog.all.filter { store.isDiscovered($0) }.count)/\(FieldGuideCatalog.all.count)")
                    }
                }
                .buttonStyle(BluePlateButtonStyle())
                Button(action: onCharts) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                        Text("HARVEST CHARTS")
                    }
                }
                .buttonStyle(BluePlateButtonStyle())
            }
        }
        .entrance(2)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RankCatalog.all) { r in
                    let reached = r.level <= rank.level
                    VStack(alignment: .leading, spacing: 2) {
                        MicroLabel(text: "Rank \(r.level)", color: reached ? Palette.stitchRed : Palette.inkSoft, size: 9)
                        Text(r.title)
                            .font(Typo.heavy(13))
                            .foregroundColor(reached ? Palette.ink : Palette.inkSoft)
                            .lineLimit(1)
                        MicroLabel(text: "\(Format.number(r.threshold)) bu", color: Palette.inkSoft, size: 8.5)
                    }
                    .padding(10)
                    .frame(width: 124, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(r.level == rank.level ? Palette.sun500 : (reached ? Palette.sun100 : Palette.linen)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: r.level == rank.level ? 3 : 1.5))
                    .opacity(reached ? 1 : 0.75)
                }
            }
            .padding(.vertical, 4)
        }

        SectionHeader(title: "Lifetime")
        let s = store.stats
        let winRate = s.totalRuns > 0 ? Double(s.totalWins) / Double(s.totalRuns) : 0
        let tiles: [(String, String)] = [
            ("\(s.totalRuns)", "runs"),
            (Format.percent(winRate), "sown rate"),
            ("\(store.totalStars)", "stars"),
            (Format.number(Int(s.totalSeedsSown)), "seeds"),
            (Format.number(Int(s.totalPlotsSown)), "plots"),
            ("\(s.totalTrueSows)", "true sows"),
            ("\(s.goldenSown)", "golden"),
            ("x\(s.bestStreak)", "best streak"),
            (Format.number(Int(s.totalPodsFlung)), "pods flung"),
            ("\(s.dailyCompleted)", "dailies"),
            ("\(max(Int(s.bestDailyStreak), store.dailyStreak))", "best days"),
            ("\(store.ribbonsEarned)/\(store.ribbonsTotal)", "ribbons")
        ]
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(tiles.indices, id: \.self) { i in
                StatWell(value: tiles[i].0, label: tiles[i].1)
            }
        }

        SectionHeader(title: "Regions", trailing: "tap for details")
        LinenCard(padding: Space.s2) {
            VStack(spacing: Space.s1) {
                ForEach(store.regionSummaries()) { summary in
                    Button { onRegion(summary.region.key) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: summary.complete ? "checkmark.seal.fill" : (summary.unlocked ? "leaf.fill" : "lock.fill"))
                            .foregroundColor(summary.complete ? Palette.leaf : (summary.unlocked ? Palette.sun600 : Palette.lockedArt))
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(summary.region.name)
                                    .font(Typo.heavy(14))
                                    .foregroundColor(summary.unlocked ? Palette.ink : Palette.inkSoft)
                                Spacer()
                                MicroLabel(text: summary.unlocked ? "\(summary.sown)/\(summary.region.fieldCount) · \(summary.stars)★"
                                                                  : "Opens at \(summary.region.starGate)★",
                                           color: Palette.inkSoft, size: 9.5)
                            }
                            StripedBar(value: Double(summary.sown) / Double(summary.region.fieldCount), height: 8)
                                .opacity(summary.unlocked ? 1 : 0.4)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Palette.inkSoft)
                    }
                    .padding(.vertical, 4)
                    }
                    .buttonStyle(RowPressStyle())
                    .accessibilityLabel("\(summary.region.name), \(summary.sown) of \(summary.region.fieldCount) sown")
                }
            }
        }

        SectionHeader(title: "Closest ribbons")
        let closest = store.ribbonEntities()
            .filter { !$0.isEarned }
            .sorted { Double($0.progress) / Double(max(1, $0.goal)) > Double($1.progress) / Double(max(1, $1.goal)) }
            .prefix(3)
        if closest.isEmpty {
            EdgeStateCard(art: "ribbon_badge_hero", title: "Every ribbon pinned",
                          message: "All forty ribbons hang on the barn door. The Daily Sowing still turns every morning.") {
                Button("Open Daily Sowing", action: onDaily).buttonStyle(BluePlateButtonStyle())
            }
        } else {
            LinenCard(padding: Space.s2) {
                VStack(spacing: 12) {
                    ForEach(Array(closest), id: \.objectID) { ribbon in
                        HStack(spacing: 12) {
                            Rosette(earned: false, size: 34)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ribbon.title ?? "").font(Typo.heavy(14)).foregroundColor(Palette.ink)
                                Text(ribbon.detail ?? "").font(Typo.medium(12)).foregroundColor(Palette.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                StripedBar(value: Double(ribbon.progress) / Double(max(1, ribbon.goal)), height: 8)
                            }
                            MicroLabel(text: "\(Format.number(Int(ribbon.progress)))/\(Format.number(Int(ribbon.goal)))", color: Palette.inkSoft, size: 9)
                        }
                    }
                }
            }
        }
    }

    // MARK: ledger

    private var filteredRuns: [RunRecordEntity] {
        runs.filter { run in
            switch filter {
            case .all: return true
            case .sown: return run.outcome == "sown"
            case .fallow: return run.outcome == "fallow"
            case .daily: return run.dailyKey != nil
            }
        }
    }

    @ViewBuilder
    private var ledger: some View {
        if runs.isEmpty {
            EdgeStateCard(art: "crate_seeds", title: "The ledger is empty",
                          message: "Nothing written down yet. Finish a run — sown or fallow — and it lands here with its score, seed and stars.") {
                Button { onPlayField(store.currentFieldIndex) } label: { Text("SOW FIELD \(store.currentFieldIndex + 1)") }
                    .buttonStyle(PlankButtonStyle(fontSize: 18))
            }
            .padding(.top, 6)
        } else {
            StitchSegments(options: [(LedgerFilter.all, "All"), (LedgerFilter.sown, "Sown"),
                                     (LedgerFilter.fallow, "Fallow"), (LedgerFilter.daily, "Daily")],
                           selection: $filter)
            let list = filteredRuns
            let best = list.map { Int($0.score) }.max() ?? 0
            let average = list.isEmpty ? 0 : list.reduce(0) { $0 + Int($1.score) } / list.count
            HStack(spacing: 8) {
                StatWell(value: "\(list.count)", label: "runs", size: 22)
                StatWell(value: Format.number(best), label: "best", size: 22)
                StatWell(value: Format.number(average), label: "average", size: 22)
            }
            Button(action: onCharts) {
                HStack(spacing: Space.s1) {
                    Image(systemName: "chart.bar.xaxis").foregroundColor(Palette.blue700)
                    MicroLabel(text: "See these runs as charts", color: Palette.blue700)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .black)).foregroundColor(Palette.blue700)
                }
                .padding(.horizontal, Space.s2)
                .frame(minHeight: 44)
                .background(LinenSurface(radius: 14))
            }
            .buttonStyle(RowPressStyle())
            if list.isEmpty {
                EdgeStateCard(art: filter == .fallow ? "plot_sown" : "plot_bare",
                              title: filter == .fallow ? "Nothing left fallow" : "Nothing here yet",
                              message: filter == .fallow ? "Every run in this ledger bloomed. Tidy work."
                                                         : "Runs of this kind will be written here as you play.") {
                    EmptyView()
                }
            } else {
                LinenCard(padding: 12) {
                    VStack(spacing: 0) {
                        ForEach(Array(list.enumerated()), id: \.element.objectID) { index, run in
                            Button { openRun = run.objectID } label: { LedgerRow(run: run) }
                                .buttonStyle(RowPressStyle())
                                .entrance(min(index, 8))
                            if index < list.count - 1 { DashedRule(color: Palette.ink.opacity(0.22)) }
                        }
                    }
                }
            }
        }
    }

}

private struct LedgerRow: View {
    let run: RunRecordEntity

    var body: some View {
        let sown = run.outcome == "sown"
        HStack(spacing: 12) {
            SeedArt(key: run.seedKey ?? "rye", size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.dailyKey != nil ? "Daily · \(DailyRules.shortLabel(run.dailyKey ?? ""))" : "Field \(run.fieldIndex + 1)")
                    .font(Typo.heavy(15))
                    .foregroundColor(Palette.ink)
                MicroLabel(text: "\(Region.forKey(run.regionKey).name) · \(Format.relative(run.createdAt ?? Date()))",
                           color: Palette.inkSoft, size: 9)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Format.number(Int(run.score)))
                    .font(Typo.thin(20))
                    .foregroundColor(Palette.ink)
                    .monospacedDigit()
                if sown {
                    StarDiamonds(stars: Int(run.starsEarned), size: 9)
                } else {
                    MicroLabel(text: "Fallow", color: Palette.stitchRed, size: 9)
                }
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

/// Full detail of one ledger entry.
struct RunDetailView: View {
    let run: RunRecordEntity
    let onClose: () -> Void
    let onReplay: () -> Void
    var onSeed: (() -> Void)? = nil

    var body: some View {
        let sown = run.outcome == "sown"
        let seed = SeedCatalog.variety(run.seedKey)
        ZStack {
            Palette.blue950.opacity(0.5).ignoresSafeArea().onTapGesture {
                Haptics.shared.tap()
                onClose()
            }
            ScrollView(showsIndicators: false) {
                LinenCard(padding: Space.s3) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                MicroLabel(text: "\(Region.forKey(run.regionKey).name) · \(Format.relative(run.createdAt ?? Date()))",
                                           color: Palette.stitchRed)
                                Text(run.dailyKey != nil ? "Daily Sowing" : "Field \(run.fieldIndex + 1)")
                                    .font(Typo.heavy(30))
                                    .foregroundColor(Palette.ink)
                                Text(sown ? "Sown" : "Left fallow")
                                    .font(Typo.heavy(14))
                                    .foregroundColor(sown ? Palette.leaf : Palette.stitchRed)
                            }
                            Spacer()
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(Palette.ink)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Palette.sun100))
                                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2.5))
                            }
                            .buttonStyle(ArtPressStyle())
                            .accessibilityLabel("Close")
                        }
                        HStack(alignment: .bottom) {
                            RollingText(text: Format.number(Int(run.score)))
                                .font(Typo.thin(56))
                                .foregroundColor(Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer()
                            StarDiamonds(stars: Int(run.starsEarned), size: 16)
                        }
                        DashedRule()
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            StatWell(value: "\(run.plotsSown)/\(run.plotsRequired)", label: "plots", size: 20)
                            StatWell(value: "\(run.podsUsed)", label: "pods used", size: 20)
                            StatWell(value: "\(run.podsLeft)", label: "pods left", size: 20)
                            StatWell(value: "x\(run.bestStreak)", label: "streak", size: 20)
                            StatWell(value: "\(run.trueSows)", label: "true sows", size: 20)
                            StatWell(value: "\(run.seedsLost)", label: "seeds lost", size: 20)
                            StatWell(value: "\(run.goldenSown)", label: "golden", size: 20)
                            StatWell(value: "+\(run.bushels)", label: "bushels", size: 20)
                            StatWell(value: Format.duration(run.durationSeconds), label: "time", size: 20)
                        }
                        Button { onSeed?() } label: {
                            HStack(spacing: 12) {
                                SeedArt(key: seed.key, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    MicroLabel(text: "Seed used", color: Palette.inkSoft, size: 9.5)
                                    Text("\(seed.name) · \(seed.traitLine)").font(Typo.heavy(14)).foregroundColor(Palette.ink)
                                }
                                Spacer()
                                if onSeed != nil {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(Palette.inkSoft)
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                        }
                        .buttonStyle(RowPressStyle())
                        .disabled(onSeed == nil)
                        .accessibilityLabel("Seed used: \(seed.name). Open seed page")
                        Button(action: onReplay) {
                            Text(run.dailyKey != nil ? "OPEN DAILY SOWING" : "SOW THIS FIELD AGAIN")
                        }
                        .buttonStyle(PlankButtonStyle(fontSize: 18))
                        .breathe(0.02)
                    }
                }
                .entrance(0)
                .padding(.horizontal, 18)
                .padding(.vertical, 36)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
