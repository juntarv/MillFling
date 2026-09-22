import SwiftUI

/// Library of everything you meet in the valley: plots, hazards, wind and sowing skills.
struct FieldGuideView: View {
    @EnvironmentObject private var store: FarmStore
    let onBack: () -> Void
    let onPlay: (Int) -> Void

    @State private var shelf: GuideShelf?
    @State private var selectedKey: String = FieldGuideCatalog.all[0].key

    var body: some View {
        let _ = store.revision
        let discovered = FieldGuideCatalog.all.filter { store.isDiscovered($0) }.count
        let entries = FieldGuideCatalog.all.filter { shelf == nil || $0.shelf == shelf }
        let spotlight = FieldGuideCatalog.entry(selectedKey) ?? FieldGuideCatalog.all[0]

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_field_rows", wash: 0.3)
            AmbientMotes(count: 14).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "\(discovered) of \(FieldGuideCatalog.all.count) discovered", title: "Field Guide", onBack: onBack) {
                        Art(UIImage.exists("icon_info") ? "icon_info" : "pod_seed")
                            .frame(width: 38, height: 38)
                            .sway(4, period: 2.6, anchor: .bottom)
                    }
                    .entrance(0)

                    spotlightCard(spotlight)
                        .id(spotlight.key)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .entrance(1)

                    StitchSegments(options: shelfOptions, selection: $shelf)
                        .entrance(2)

                    SectionHeader(title: shelf?.title ?? "Everything in the valley", trailing: "\(entries.count)")

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s2), GridItem(.flexible(), spacing: Space.s2)],
                              spacing: Space.s2) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            let known = store.isDiscovered(entry)
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedKey = entry.key }
                            } label: {
                                VStack(alignment: .leading, spacing: Space.s1) {
                                    GuideArtView(art: entry.art, size: 52)
                                        .saturation(known ? 1 : 0)
                                        .opacity(known ? 1 : 0.4)
                                        .frame(maxWidth: .infinity)
                                    Text(known ? entry.title : "Not met yet")
                                        .font(Typo.heavy(15))
                                        .foregroundColor(known ? Palette.ink : Palette.inkSoft)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    MicroLabel(text: known ? entry.shelf.title : "Field \(entry.firstField + 1)",
                                               color: known ? Palette.inkSoft : Palette.lockedArt, size: 9)
                                }
                                .padding(Space.s2 - 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(LinenSurface(radius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Palette.stitchRed, lineWidth: entry.key == selectedKey ? 3 : 0))
                            }
                            .buttonStyle(ArtPressStyle())
                            .entrance(3 + index % 6)
                            .accessibilityLabel(known ? entry.title : "Undiscovered entry, first seen on field \(entry.firstField + 1)")
                        }
                    }
                }
                .screenPadding()
            }

            TopStitchBand()
        }
    }

    private var shelfOptions: [(GuideShelf?, String)] {
        var options: [(GuideShelf?, String)] = [(nil, "All")]
        for shelf in GuideShelf.allCases { options.append((shelf, shelf.title)) }
        return options
    }

    private func spotlightCard(_ entry: GuideEntry) -> some View {
        let known = store.isDiscovered(entry)
        let first = FieldCatalog.field(entry.firstField)
        return LinenCard(padding: Space.s3) {
            VStack(alignment: .leading, spacing: Space.s2) {
                HStack(alignment: .center, spacing: Space.s2) {
                    GuideArtView(art: entry.art, size: 84)
                        .saturation(known ? 1 : 0)
                        .opacity(known ? 1 : 0.45)
                        .padding(Space.s1)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.sun100))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Palette.ink, lineWidth: 3))
                        .bob(3, period: 2)
                    VStack(alignment: .leading, spacing: 4) {
                        MicroLabel(text: entry.shelf.title, color: Palette.stitchRed)
                        Text(known ? entry.title : "Still out in the fields")
                            .font(Typo.heavy(26))
                            .foregroundColor(Palette.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                        MicroLabel(text: "First met on field \(first.number) · \(first.region.name)", color: Palette.inkSoft, size: 9.5)
                    }
                }
                if known {
                    Text(entry.body)
                        .font(Typo.medium(15))
                        .foregroundColor(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .top, spacing: Space.s1) {
                        Image(systemName: "lightbulb.fill").foregroundColor(Palette.sun600)
                        Text(entry.tip)
                            .font(Typo.medium(14))
                            .foregroundColor(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let value = store.statValue(entry.stat) {
                        HStack(alignment: .firstTextBaseline, spacing: Space.s1) {
                            RollingText(text: entry.stat == .bestStreak ? "x\(value)" : Format.number(value))
                                .font(Typo.thin(34))
                                .foregroundColor(Palette.ink)
                            MicroLabel(text: entry.statLabel, color: Palette.inkSoft)
                        }
                    }
                    if store.isUnlocked(field: entry.firstField) {
                        Button { onPlay(entry.firstField) } label: {
                            Text("PRACTISE ON FIELD \(first.number)")
                        }
                        .buttonStyle(BluePlateButtonStyle())
                    }
                } else {
                    Text("Keep sowing — you'll meet this one when you reach field \(first.number) in \(first.region.name).")
                        .font(Typo.medium(15))
                        .foregroundColor(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Art for a guide entry: harvested assets, or small drawn tiles for plots and skills.
struct GuideArtView: View {
    let art: GuideArt
    var size: CGFloat = 52

    var body: some View {
        switch art {
        case .image(let name):
            Art(name).frame(width: size, height: size)
        case .tile(let kind):
            RoundedRectangle(cornerRadius: size * 0.14)
                .fill(tileColor(kind))
                .overlay(RoundedRectangle(cornerRadius: size * 0.14).strokeBorder(Palette.ink, lineWidth: 3))
                .overlay(tileMark(kind))
                .frame(width: size, height: size * 0.78)
                .frame(width: size, height: size)
        case .target:
            ZStack {
                Circle().fill(Palette.sun500).overlay(Circle().strokeBorder(Palette.ink, lineWidth: 3))
                Circle().fill(Palette.linen).frame(width: size * 0.6, height: size * 0.6)
                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2))
                Circle().fill(Palette.stitchRed).frame(width: size * 0.24, height: size * 0.24)
                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2))
            }
            .frame(width: size * 0.86, height: size * 0.86)
            .frame(width: size, height: size)
        case .streak:
            Text("x6")
                .font(Typo.heavy(size * 0.4))
                .foregroundColor(Palette.ink)
                .frame(width: size * 0.9, height: size * 0.6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Palette.sun500))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.ink, lineWidth: 3))
                .rotationEffect(.degrees(-4))
                .frame(width: size, height: size)
        }
    }

    private func tileColor(_ kind: PlotKind) -> Color {
        switch kind {
        case .soil: return Color(hex: 0xA9762F)
        case .golden: return Palette.sun300
        case .pond: return Palette.blue700
        case .stone: return Color(hex: 0xB9C7DC)
        case .road: return Color(hex: 0x8FA6C6)
        }
    }

    @ViewBuilder
    private func tileMark(_ kind: PlotKind) -> some View {
        switch kind {
        case .golden:
            Image(systemName: "star.fill").font(.system(size: size * 0.3, weight: .black)).foregroundColor(Palette.linen)
                .shadow(color: Palette.ink, radius: 0, x: 1, y: 1)
        case .pond:
            Image(systemName: "water.waves").font(.system(size: size * 0.3, weight: .bold)).foregroundColor(Palette.blue100)
        case .soil:
            VStack(spacing: size * 0.1) {
                Capsule().fill(Color(hex: 0x7A4A05).opacity(0.6)).frame(width: size * 0.6, height: 3)
                Capsule().fill(Color(hex: 0x7A4A05).opacity(0.6)).frame(width: size * 0.6, height: 3)
            }
        default:
            EmptyView()
        }
    }
}
