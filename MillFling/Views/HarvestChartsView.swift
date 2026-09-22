import SwiftUI

/// Trends from the ledger: recent scores, stars by region, plots sown per day and favourite seeds.
struct HarvestChartsView: View {
    enum Mode: Hashable { case charts, table }

    @EnvironmentObject private var store: FarmStore
    let onBack: () -> Void
    let onSeed: (String) -> Void
    let onPlay: (Int) -> Void

    @State private var mode: Mode = .charts

    var body: some View {
        let _ = store.revision
        let runs = store.allRuns()

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_field_rows", wash: 0.32)
            AmbientMotes(count: 12, color: Palette.sun100).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "\(runs.count) runs in the ledger", title: "Harvest Charts", onBack: onBack) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Palette.blue700)
                            .bob(2, period: 1.8)
                    }
                    .entrance(0)

                    if runs.count < 2 {
                        EdgeStateCard(art: "sprout", title: "Charts grow as you sow",
                                      message: "Finish a couple of runs and your scores, stars and favourite seeds will start drawing themselves here.") {
                            Button { onPlay(store.currentFieldIndex) } label: { Text("SOW FIELD \(store.currentFieldIndex + 1)") }
                                .buttonStyle(PlankButtonStyle(fontSize: 18))
                        }
                    } else {
                        StitchSegments(options: [(Mode.charts, "Charts"), (Mode.table, "Table")], selection: $mode)
                            .entrance(1)
                        kpis(runs)
                            .entrance(2)
                        recentScores(runs)
                            .entrance(3)
                        starsByRegion
                            .entrance(4)
                        plotsPerDay(runs)
                            .entrance(5)
                        seedUse(runs)
                            .entrance(6)
                    }
                }
                .screenPadding()
            }

            TopStitchBand()
        }
    }

    // MARK: headline numbers (stat tiles, not charts)

    private func kpis(_ runs: [RunRecordEntity]) -> some View {
        let recent = Array(runs.suffix(12))
        let average = recent.isEmpty ? 0 : recent.reduce(0) { $0 + Int($1.score) } / recent.count
        let sownRate = runs.isEmpty ? 0 : Double(runs.filter { $0.outcome == "sown" }.count) / Double(runs.count)
        var byRegion: [String: Int] = [:]
        for run in runs where run.dailyKey == nil { byRegion[run.regionKey ?? "", default: 0] += 1 }
        let busiest = byRegion.max { $0.value < $1.value }.map { Region.forKey($0.key).name } ?? "—"
        return VStack(spacing: Space.s1) {
            HStack(spacing: Space.s1) {
                StatWell(value: Format.number(average), label: "avg of last 12", size: 22)
                StatWell(value: Format.percent(sownRate), label: "sown rate", size: 22)
                StatWell(value: "x\(store.stats.bestStreak)", label: "best streak", size: 22)
            }
            HStack(spacing: Space.s1) {
                Image(systemName: "mappin.and.ellipse").foregroundColor(Palette.stitchRed)
                Text("Most played: \(busiest)")
                    .font(Typo.heavy(14))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Space.s2)
            .frame(minHeight: 44)
            .background(LinenSurface(radius: 14))
        }
    }

    // MARK: charts

    private func recentScores(_ runs: [RunRecordEntity]) -> some View {
        let recent = Array(runs.suffix(12))
        let data = recent.enumerated().map { index, run in
            ChartDatum(id: "run-\(index)",
                       label: Format.relative(run.createdAt ?? Date()),
                       value: Double(run.score),
                       muted: run.outcome != "sown",
                       detail: run.dailyKey != nil ? "Daily · \(DailyRules.shortLabel(run.dailyKey ?? ""))" : "Field \(run.fieldIndex + 1)")
        }
        let wins = recent.filter { $0.outcome == "sown" }.count
        return ChartCard(title: "Recent scores",
                         takeaway: "\(wins) of your last \(recent.count) runs were sown. Tap a bar for the field.") {
            if mode == .charts {
                ColumnChart(data: data)
                ChartLegend(items: [("Sown", ChartInk.series), ("Fallow", ChartInk.muted)])
            } else {
                ChartTable(data: data.reversed())
            }
        }
    }

    private var starsByRegion: some View {
        let summaries = store.regionSummaries()
        let data = summaries.map { s in
            ChartDatum(id: s.region.id, label: s.region.name, value: Double(s.stars), muted: !s.unlocked,
                       detail: s.region.name)
        }
        let total = summaries.reduce(0) { $0 + $1.stars }
        let best = summaries.max { $0.stars < $1.stars }
        return ChartCard(title: "Stars by region",
                         takeaway: "\(total) of \(FieldCatalog.count * 3) stars so far — most in \(best?.region.name ?? "the Meadow").") {
            if mode == .charts {
                BarRowsChart(data: data, maxValue: 27) { d in
                    summaries.first { $0.region.id == d.id }?.unlocked == true ? "\(Int(d.value))/27" : "locked"
                }
            } else {
                ChartTable(data: data) { d in "\(Int(d.value)) of 27" }
            }
        }
    }

    private func plotsPerDay(_ runs: [RunRecordEntity]) -> some View {
        let today = DailyRules.dayKey(for: Date())
        let keys = DailyRules.recentKeys(count: 14, today: today)
        var plots: [String: Int] = [:]
        for run in runs {
            let key = DailyRules.dayKey(for: run.createdAt ?? Date())
            plots[key, default: 0] += Int(run.plotsSown)
        }
        let data = keys.map { key in
            ChartDatum(id: key, label: DailyRules.shortLabel(key), value: Double(plots[key] ?? 0),
                       detail: DailyRules.longLabel(key))
        }
        let busiest = data.max { $0.value < $1.value }
        return ChartCard(title: "Plots sown per day",
                         takeaway: busiest.map { $0.value > 0 ? "Busiest day: \($0.detail) with \(Int($0.value)) plots." : "No plots in the last two weeks yet." }
                            ?? "No plots in the last two weeks yet.") {
            if mode == .charts {
                ColumnChart(data: data, height: 120)
            } else {
                ChartTable(data: data.reversed())
            }
        }
    }

    private func seedUse(_ runs: [RunRecordEntity]) -> some View {
        var counts: [String: Int] = [:]
        for run in runs { counts[run.seedKey ?? "rye", default: 0] += 1 }
        let top = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.prefix(6)
        let data = top.map { entry in
            ChartDatum(id: entry.key, label: SeedCatalog.variety(entry.key).name, value: Double(entry.value),
                       detail: SeedCatalog.variety(entry.key).name, icon: "seed_\(entry.key)")
        }
        return ChartCard(title: "Seeds you sow most",
                         takeaway: data.first.map { "\($0.label) rides the sails most often. Tap a seed for its page." } ?? "") {
            if mode == .charts {
                BarRowsChart(data: data, labelWidth: 84) { d in "\(Int(d.value)) runs" }
                HStack(spacing: Space.s1) {
                    ForEach(data) { d in
                        Button { onSeed(d.id) } label: {
                            SeedArt(key: d.id, size: 30)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Palette.sun100))
                                .overlay(Circle().strokeBorder(Palette.ink.opacity(0.3), lineWidth: 1.5))
                        }
                        .buttonStyle(ArtPressStyle())
                        .accessibilityLabel("Open \(d.label)")
                    }
                    Spacer(minLength: 0)
                }
            } else {
                ChartTable(data: Array(data)) { d in "\(Int(d.value)) runs" }
            }
        }
    }
}
