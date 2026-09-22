import SwiftUI

/// End-of-run report: "Field sown" with stars and roll-up, or "Field left fallow".
struct HarvestReportView: View {
    let report: HarvestReport
    let onNext: () -> Void
    let onReplay: () -> Void
    let onFieldMap: () -> Void
    let onDaily: () -> Void

    @Environment(\.motionEnabled) private var motion
    @State private var shownStars = 0
    @State private var displayedScore = 0
    @State private var stampIn = false

    private var sown: Bool { report.outcome == .sown }

    var body: some View {
        ZStack {
            Palette.blue950.opacity(0.46).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Space.s2) {
                    rosettes
                        .background(
                            ZStack {
                                ForEach(0..<12, id: \.self) { i in
                                    Capsule()
                                        .fill(Palette.sun300.opacity(sown ? 0.55 : 0.2))
                                        .frame(width: 6, height: 70)
                                        .offset(y: -70)
                                        .rotationEffect(.degrees(Double(i) * 30))
                                }
                            }
                            .spin(period: 16)
                            .allowsHitTesting(false)
                        )
                        .padding(.top, Space.s3)

                    LinenCard(padding: Space.s3) {
                        VStack(alignment: .leading, spacing: Space.s1 + 2) {
                            MicroLabel(text: report.isDaily ? "Daily Sowing · \(report.dailyLabel)" : "\(report.regionName) · Field \(report.fieldNumber)",
                                       color: Palette.stitchRed)
                            Text(sown ? "Field sown" : "Field left fallow")
                                .font(Typo.heavy(Typo.titleSize))
                                .foregroundColor(Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            ZStack(alignment: .topTrailing) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(Format.number(displayedScore))
                                        .font(Typo.thin(62))
                                        .foregroundColor(Palette.ink)
                                        .monospacedDigit()
                                        .contentTransition(.numericText())
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                    MicroLabel(text: sown ? "Harvest score" : "Score this run", color: Palette.inkSoft)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                if report.isNewBest {
                                    Art("best_stamp")
                                        .frame(width: 104, height: 52)
                                        .rotationEffect(.degrees(-8))
                                        .scaleEffect(stampIn ? 1 : 2.2)
                                        .opacity(stampIn ? 1 : 0)
                                        .offset(y: 16)
                                }
                            }
                            DashedRule().padding(.vertical, 6)
                            Group {
                            row("Plots sown", "\(report.plotsSown) / \(report.quota)")
                            row("Pods left", "\(report.podsLeft) of \(report.podsTotal)")
                            row("Best streak", "x\(report.bestStreak)")
                            row("Seeds landed", "\(report.seedsLanded)")
                            row("Seed used", report.seedName)
                            if report.goldenTotal > 0 {
                                row("Golden plots", "\(report.goldenSown) / \(report.goldenTotal)")
                            }
                            }
                            harvestBlock
                            Group {
                            ForEach(report.earnedRibbons, id: \.self) { title in
                                note(icon: "ribbon_badge", text: "Ribbon earned: ", strong: title)
                            }
                            ForEach(report.unlockedSeeds, id: \.self) { name in
                                note(icon: "seed_\(name.lowercased())", text: "New seed in the crate: ", strong: name)
                            }
                            if !sown {
                                note(icon: "plot_bare", text: "Still bare: ", strong: "\(max(0, report.quota - report.plotsSown)) plots")
                            }
                            if let gate = report.gateMessage {
                                note(icon: "rosette_ribbon", text: "", strong: gate)
                            }
                            if let region = report.regionCleared {
                                note(icon: "post_fields", text: "Region complete: ", strong: region)
                            }
                            ForEach(report.unlockedPaints, id: \.self) { paint in
                                note(icon: "mill_sails", text: "New mill paint: ", strong: paint)
                            }
                            if report.isDaily && report.firstDailyToday {
                                note(icon: "icon_app_mark", text: "Daily streak: ", strong: "\(report.dailyStreak) day\(report.dailyStreak == 1 ? "" : "s")")
                            }
                            }
                        }
                    }
                    .entrance(1)

                    VStack(spacing: 12) {
                        if report.isDaily {
                            Button(action: onDaily) {
                                HStack(spacing: 10) {
                                    Text("BACK TO DAILY SOWING")
                                    Image(systemName: "sun.max.fill").font(.system(size: 18, weight: .black))
                                }
                            }
                            .buttonStyle(PlankButtonStyle(fontSize: 20))
                            Button(sown ? "Replay today's field" : "Try again", action: onReplay)
                                .buttonStyle(BluePlateButtonStyle())
                        } else if sown && report.nextFieldUnlocked && report.fieldIndex + 1 < FieldCatalog.count {
                            Button(action: onNext) {
                                HStack(spacing: 10) {
                                    Text("NEXT FIELD")
                                    Image(systemName: "arrow.right").font(.system(size: 20, weight: .black))
                                }
                            }
                            .buttonStyle(PlankButtonStyle(fontSize: 24))
                            .breathe(0.02)
                        } else if !sown {
                            Button(action: onReplay) { Text("TRY AGAIN") }
                                .buttonStyle(PlankButtonStyle(fontSize: 24))
                        }
                        if !report.isDaily {
                            HStack(spacing: 12) {
                                if sown {
                                    Button("Replay field", action: onReplay).buttonStyle(BluePlateButtonStyle())
                                }
                                Button("Field map", action: onFieldMap).buttonStyle(BluePlateButtonStyle())
                            }
                        }
                    }
                    .padding(.top, 6)
                    .padding(.bottom, Space.s3)
                    .entrance(3)
                }
                .padding(.horizontal, Space.s3)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear(perform: animateIn)
    }

    private var rosettes: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<3, id: \.self) { i in
                let earned = i < report.stars
                Rosette(earned: earned, size: i == 1 ? 78 : 60)
                    .scaleEffect(i < shownStars || !earned ? 1 : 0.2)
                    .opacity(i < shownStars || !earned ? 1 : 0)
                    .offset(y: i == 1 ? -8 : 0)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(report.stars) of 3 stars")
    }

    /// Bushels earned and progress toward the next farmer rank.
    private var harvestBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("+\(report.bushels)")
                    .font(Typo.thin(34))
                    .foregroundColor(Palette.ink)
                    .contentTransition(.numericText())
                MicroLabel(text: "bushels", color: Palette.inkSoft)
                Spacer()
                MicroLabel(text: "Rank \(report.rankLevel) · \(report.rankTitle)", color: report.rankedUp ? Palette.stitchRed : Palette.inkSoft)
            }
            StripedBar(value: report.rankProgress, height: 10)
            if report.rankedUp {
                Text("Rank up! You are now a \(report.rankTitle).")
                    .font(Typo.heavy(14))
                    .foregroundColor(Palette.stitchRed)
            } else if let next = report.nextRankTitle {
                MicroLabel(text: "Next rank: \(next)", color: Palette.inkSoft, size: 9.5)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.3), lineWidth: 2))
        .padding(.top, 4)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Typo.heavy(Typo.smallSize)).foregroundColor(Palette.inkSoft)
            Spacer()
            Text(value).font(Typo.heavy(Typo.smallSize)).foregroundColor(Palette.ink)
        }
    }

    private func note(icon: String, text: String, strong: String) -> some View {
        HStack(spacing: 10) {
            Art(icon).frame(width: 26, height: 30)
            (Text(text).foregroundColor(Palette.inkSoft) + Text(strong).foregroundColor(Palette.ink))
                .font(Typo.heavy(13))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
    }

    private func animateIn() {
        guard motion else {
            displayedScore = report.score
            shownStars = report.stars
            stampIn = true
            return
        }
        withAnimation(.easeOut(duration: 1.0)) { displayedScore = report.score }
        for i in 0..<report.stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.28) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { shownStars = i + 1 }
                Haptics.shared.sow()
            }
        }
        if report.isNewBest {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { stampIn = true }
                Haptics.shared.burst()
            }
        }
    }
}
