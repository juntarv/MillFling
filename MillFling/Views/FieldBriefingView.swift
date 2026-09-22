import SwiftUI

/// Pre-run detail sheet: the field's layout, targets, hazards, your record and recent runs.
/// Header (title + close) and footer (seed + SOW) are pinned; only the middle scrolls when space runs out.
struct FieldBriefingView: View {
    @EnvironmentObject private var store: FarmStore
    let fieldIndex: Int
    let onClose: () -> Void
    let onSow: (Int) -> Void
    let onAlmanac: () -> Void
    var onGuide: (() -> Void)? = nil

    var body: some View {
        let _ = store.revision
        ZStack {
            Palette.blue950.opacity(0.52).ignoresSafeArea()
                .onTapGesture {
                    Haptics.shared.tap()
                    onClose()
                }
            GeometryReader { geo in
                // short screens (iPhone SE) get a tighter card so more of the briefing fits above the footer
                let compact = geo.size.height < 720
                ViewThatFits(in: .vertical) {
                    card(scrolling: false, compact: compact)
                    card(scrolling: true, compact: compact)
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, Space.s2)
                .padding(.top, Space.band + (compact ? Space.s1 : Space.s2))
                .padding(.bottom, compact ? Space.s1 : Space.s2)
                .frame(width: geo.size.width, height: geo.size.height)
                .entrance(0)
            }
        }
    }

    // MARK: card

    private func card(scrolling: Bool, compact: Bool) -> some View {
        let inset = compact ? Space.s2 : Space.s3
        return VStack(spacing: 0) {
            header(compact)
                .padding(.horizontal, inset)
                .padding(.top, compact ? Space.s2 : Space.s3)
                .padding(.bottom, compact ? Space.s1 + 4 : Space.s2)
            DashedRule(color: Palette.ink.opacity(0.25))
            if scrolling {
                ScrollView(showsIndicators: true) {
                    details(compact)
                        .padding(.horizontal, inset)
                        .padding(.top, Space.s2)
                        // room so the last line can scroll fully clear of the bottom fade
                        .padding(.bottom, Space.s5)
                }
                // soft edges: no text line is ever cut mid-glyph by the dividers
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 12)
                        Color.black
                        LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 40)
                    }
                )
                .overlay(alignment: .bottom) {
                    ScrollMoreHint().padding(.bottom, 6)
                }
            } else {
                details(compact)
                    .padding(.horizontal, inset)
                    .padding(.vertical, Space.s2)
            }
            DashedRule(color: Palette.ink.opacity(0.25))
            footer(compact)
                .padding(.horizontal, inset)
                .padding(.top, compact ? Space.s1 + 4 : Space.s2)
                .padding(.bottom, compact ? Space.s2 : Space.s3)
        }
        .background(LinenSurface(radius: Radius.md))
    }

    private func header(_ compact: Bool) -> some View {
        let field = FieldCatalog.field(fieldIndex)
        let stars = Int(store.progress(field: fieldIndex)?.stars ?? 0)
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                MicroLabel(text: "\(field.region.name) · \(field.number) of \(FieldCatalog.count)", color: Palette.stitchRed)
                Text("Field \(field.number)")
                    .font(Typo.heavy(compact ? 26 : Typo.titleSize))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                StarDiamonds(stars: stars, size: 14)
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
            .accessibilityLabel("Close briefing")
        }
    }

    private func details(_ compact: Bool) -> some View {
        let field = FieldCatalog.field(fieldIndex)
        let progress = store.progress(field: fieldIndex)
        let runs = store.runs(forField: fieldIndex, limit: 5)
        let stars = Int(progress?.stars ?? 0)
        return VStack(alignment: .leading, spacing: compact ? Space.s1 + 4 : Space.s2) {
            FieldPreview(field: field)
                .frame(height: CGFloat(field.rows) * (compact ? 14 : 24))
                .padding(compact ? 6 : 10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0xFFD873)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.ink, lineWidth: 2.5))

            HStack(spacing: Space.s1) {
                StatWell(value: "\(field.quota)", label: "to sow", size: compact ? 18 : 24)
                StatWell(value: "\(field.pods)", label: "pods", size: compact ? 18 : 24)
                StatWell(value: FieldBriefingView.sailWord(field.sailSpeed), label: "sails", size: compact ? 18 : 24)
            }
            HStack(spacing: 10) {
                Art("windvane_icon").frame(width: 22, height: 22)
                    .padding(6)
                    .background(Circle().fill(Palette.blue700))
                Text(field.wind.summary)
                    .font(Typo.heavy(14))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                MicroLabel(text: "On this field", color: Palette.inkSoft)
                Text(field.hazardLines.isEmpty ? "Open soil, no hazards." : field.hazardLines.joined(separator: " · "))
                    .font(Typo.heavy(14))
                    .foregroundColor(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let tip = field.tip {
                    Text(tip)
                        .font(Typo.medium(14))
                        .foregroundColor(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let onGuide {
                    Button(action: onGuide) {
                        HStack(spacing: 6) {
                            Image(systemName: "book.fill").font(.system(size: 12, weight: .bold))
                            MicroLabel(text: "What's out there? Field guide", color: Palette.blue700, size: 10)
                        }
                        .foregroundColor(Palette.blue700)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(RowPressStyle())
                }
            }

            DashedRule()

            VStack(alignment: .leading, spacing: Space.s1) {
                MicroLabel(text: "Ribbon targets", color: Palette.inkSoft)
                target(1, "Sow \(field.quota) plots", met: stars >= 1)
                target(2, "Score \(Format.number(field.score2))", met: stars >= 2)
                target(3, "Score \(Format.number(field.score3)) with \(field.podsLeftFor3)+ pods left", met: stars >= 3)
            }

            DashedRule(color: Palette.ink.opacity(0.35))

            VStack(alignment: .leading, spacing: Space.s1) {
                MicroLabel(text: "Your record", color: Palette.inkSoft)
                if let progress, progress.attempts > 0 {
                    HStack(spacing: Space.s1) {
                        StatWell(value: Format.number(Int(progress.bestScore)), label: "best", size: 20)
                        StatWell(value: "\(progress.attempts)", label: "tries", size: 20)
                        StatWell(value: "x\(progress.bestStreak)", label: "streak", size: 20)
                    }
                    if !runs.isEmpty {
                        VStack(spacing: 6) {
                            ForEach(runs, id: \.objectID) { run in
                                RunLine(run: run)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        Art("plot_bare").frame(width: 34, height: 28)
                        Text("Not sown yet. The first clear pays +40 bushels.")
                            .font(Typo.medium(14))
                            .foregroundColor(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func footer(_ compact: Bool) -> some View {
        let seed = store.selectedSeed
        let stars = Int(store.progress(field: fieldIndex)?.stars ?? 0)
        return VStack(spacing: compact ? Space.s1 : Space.s1 + 4) {
            Button(action: onAlmanac) {
                HStack(spacing: 12) {
                    SeedArt(key: seed.key, size: compact ? 28 : 32)
                    VStack(alignment: .leading, spacing: 2) {
                        MicroLabel(text: "In the hopper", color: Palette.inkSoft, size: 9.5)
                        Text("\(seed.name) · \(seed.seedsPerBurst) per burst")
                            .font(Typo.heavy(14))
                            .foregroundColor(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 4)
                    MicroLabel(text: "Change", color: Palette.stitchRed)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Palette.ink)
                }
                .padding(.horizontal, 10)
                .frame(minHeight: compact ? 44 : 48)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.3), lineWidth: 2))
            }
            .buttonStyle(ArtPressStyle())

            Button { onSow(fieldIndex) } label: {
                HStack(spacing: 10) {
                    Text(stars > 0 ? "SOW AGAIN" : "SOW THIS FIELD")
                    Image(systemName: "arrow.right").font(.system(size: 18, weight: .black))
                }
            }
            .buttonStyle(PlankButtonStyle(fontSize: compact ? 20 : 22))
            .breathe()
        }
    }

    private func target(_ n: Int, _ text: String, met: Bool) -> some View {
        HStack(spacing: 10) {
            StarDiamonds(stars: met ? n : 0, total: n, size: 12)
                .frame(width: 50, alignment: .leading)
            Text(text)
                .font(Typo.heavy(14))
                .foregroundColor(met ? Palette.ink : Palette.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
            if met {
                Image(systemName: "checkmark.circle.fill").foregroundColor(Palette.leaf)
            }
        }
    }

    static func sailWord(_ speed: Double) -> String {
        switch speed {
        case ..<2.2: return "Slow"
        case ..<3.0: return "Brisk"
        case ..<3.8: return "Fast"
        default: return "Gale"
        }
    }
}

/// Small bobbing cue above the pinned footer: there is more to read in the scrolling middle.
private struct ScrollMoreHint: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.down").font(.system(size: 10, weight: .black))
            MicroLabel(text: "More below", color: Palette.inkSoft, size: 9)
        }
        .foregroundColor(Palette.inkSoft)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Palette.linen))
        .overlay(Capsule().strokeBorder(Palette.ink.opacity(0.25), lineWidth: 1))
        .bob(2, period: 1.2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Up to three red stitch diamonds.
struct StarDiamonds: View {
    let stars: Int
    var total: Int = 3
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(0..<total, id: \.self) { i in
                Diamond()
                    .fill(i < stars ? Palette.stitchRed : Palette.ink.opacity(0.18))
                    .overlay(Diamond().stroke(Palette.ink, lineWidth: 1.5))
                    .frame(width: size, height: size * 1.2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(stars) of \(total) stars")
    }
}

/// One compact ledger line (used in briefings and the daily page).
struct RunLine: View {
    let run: RunRecordEntity

    var body: some View {
        HStack(spacing: 10) {
            SeedArt(key: run.seedKey ?? "rye", size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(run.outcome == "sown" ? "Sown · \(Format.number(Int(run.score)))" : "Fallow · \(run.plotsSown)/\(run.plotsRequired) plots")
                    .font(Typo.heavy(13))
                    .foregroundColor(run.outcome == "sown" ? Palette.ink : Palette.inkSoft)
                MicroLabel(text: Format.relative(run.createdAt ?? Date()), color: Palette.inkSoft, size: 9)
            }
            Spacer()
            StarDiamonds(stars: Int(run.starsEarned), size: 10)
        }
        .padding(.vertical, 4)
    }
}
