import SwiftUI

/// Mill paints earned with farmer ranks. The chosen paint colours the sails on Mill Hill and in every run.
struct PaintShedView: View {
    @EnvironmentObject private var store: FarmStore
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MillPaintEntity.sortIndex, ascending: true)])
    private var paints: FetchedResults<MillPaintEntity>

    let onBack: () -> Void
    @State private var previewKey: String?

    var body: some View {
        let _ = store.revision
        let selected = store.selectedPaint
        let preview = PaintCatalog.paint(previewKey ?? selected.key)
        let previewEntity = paints.first { $0.key == preview.key }
        let unlockedCount = paints.filter(\.isUnlocked).count
        let rank = store.rank

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_menu", wash: 0.3)
            AmbientMotes(count: 14, color: Palette.linen).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "\(unlockedCount) of \(PaintCatalog.all.count) paints · rank \(rank.level)",
                                 title: "Paint Shed", onBack: onBack)
                        .entrance(0)

                    LinenCard(padding: Space.s2) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [Palette.blue700, Palette.blue500, Palette.blue300],
                                                         startPoint: .top, endPoint: .bottom))
                                Ellipse().fill(Color(hex: 0xFFD873))
                                    .frame(height: 70)
                                    .offset(y: 86)
                                WindmillView(towerWidth: 104, spinning: store.preference.animationsOn, period: 9, paint: preview.color)
                                    .id(preview.key)
                                    .offset(y: 8)
                            }
                            .frame(height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.ink, lineWidth: 3))

                            VStack(spacing: 4) {
                                Text(preview.name)
                                    .font(Typo.heavy(24))
                                    .foregroundColor(Palette.ink)
                                Text(preview.lore)
                                    .font(Typo.medium(14))
                                    .foregroundColor(Palette.inkSoft)
                                    .multilineTextAlignment(.center)
                            }

                            if preview.key == selected.key {
                                MicroLabel(text: "On the mill now", color: Palette.leaf)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.3), lineWidth: 2))
                            } else if previewEntity?.isUnlocked == true {
                                Button {
                                    Haptics.shared.success()
                                    store.selectPaint(preview.key)
                                } label: { Text("PAINT THE MILL") }
                                    .buttonStyle(PlankButtonStyle(fontSize: 20))
                                    .breathe(0.02)
                            } else {
                                let needed = RankCatalog.all.first { $0.level == preview.unlockRank }
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.fill").foregroundColor(Palette.ink)
                                    MicroLabel(text: "Reach rank \(preview.unlockRank) · \(needed?.title ?? "")")
                                }
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.barBed))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 2.5))
                            }
                        }
                    }
                    .padding(.top, Space.s1)
                    .entrance(1)

                    SectionHeader(title: "The paint rack", trailing: "\(unlockedCount)/\(PaintCatalog.all.count)")

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(paints, id: \.objectID) { entity in
                            let paint = PaintCatalog.paint(entity.key)
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { previewKey = paint.key }
                            } label: {
                                HStack(spacing: 10) {
                                    PaintedSails(paint: paint.color)
                                        .frame(width: 44, height: 44)
                                        .saturation(entity.isUnlocked ? 1 : 0.2)
                                        .bob(paint.key == selected.key ? 2 : 0, period: 1.6)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(paint.name)
                                            .font(Typo.heavy(14))
                                            .foregroundColor(entity.isUnlocked ? Palette.ink : Palette.inkSoft)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                        MicroLabel(text: paint.key == selected.key ? "On the mill"
                                                                                   : (entity.isUnlocked ? "Ready" : "Rank \(paint.unlockRank)"),
                                                   color: paint.key == selected.key ? Palette.leaf : Palette.inkSoft, size: 9)
                                    }
                                    Spacer(minLength: 0)
                                    if !entity.isUnlocked {
                                        Image(systemName: "lock.fill").font(.system(size: 12, weight: .black)).foregroundColor(Palette.inkSoft)
                                    }
                                }
                                .padding(10)
                                .background(LinenSurface(radius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Palette.stitchRed, lineWidth: paint.key == preview.key ? 3 : 0))
                            }
                            .buttonStyle(ArtPressStyle())
                            .entrance(2 + Int(entity.sortIndex) % 6)
                            .accessibilityLabel("\(paint.name), \(entity.isUnlocked ? "unlocked" : "locked until rank \(paint.unlockRank)")")
                        }
                    }

                    if unlockedCount == PaintCatalog.all.count {
                        EdgeStateCard(art: "icon_app_mark", title: "Every tin is open",
                                      message: "All ten paints are yours. Change the sails whenever the mood turns.") {
                            EmptyView()
                        }
                    }
                }
                .screenPadding()
            }

            TopStitchBand()
        }
    }
}
