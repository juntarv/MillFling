import SwiftUI

struct RibbonWallView: View {
    @EnvironmentObject private var store: FarmStore
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \RibbonEntity.sortIndex, ascending: true)])
    private var ribbons: FetchedResults<RibbonEntity>

    enum Shelf: Hashable { case all, earned, open, category(RibbonCategory) }

    let onBack: () -> Void
    @State private var selectedKey: String?
    @State private var shelf: Shelf = .all

    var body: some View {
        let _ = store.revision
        let total = ribbons.count
        let earned = ribbons.filter(\.isEarned)
        let shown = ribbons.filter { ribbon in
            switch shelf {
            case .all: return true
            case .earned: return ribbon.isEarned
            case .open: return !ribbon.isEarned
            case .category(let c): return ribbon.category == c.rawValue
            }
        }
        let newest = earned.max { ($0.earnedAt ?? .distantPast) < ($1.earnedAt ?? .distantPast) }
        let spotlight = ribbons.first { $0.key == selectedKey } ?? newest ?? ribbons.first

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_ribbons", wash: 0.28)
            AmbientMotes(count: 10, color: Palette.sun300).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "\(earned.count) of \(total) pinned", title: "Ribbon Wall", onBack: onBack)
                        .entrance(0)

                    if total > 0 && earned.count == total {
                        EdgeStateCard(art: "ribbon_badge_hero", title: "The barn door is full",
                                      message: "Every ribbon in the valley is pinned here. The Daily Sowing still turns each morning.") {
                            EmptyView()
                        }
                    }

                    if let spotlight {
                        spotlightCard(spotlight, isNewest: spotlight.objectID == newest?.objectID && selectedKey == nil,
                                      earnedCount: earned.count)
                            .entrance(1)
                    }

                    SectionHeader(title: "Pinned on the barn door", trailing: "\(shown.count)")

                    StitchSegments(options: [(Shelf.all, "All"), (Shelf.earned, "Pinned"), (Shelf.open, "To earn")],
                                   selection: $shelf)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RibbonCategory.allCases) { category in
                                let active = shelf == .category(category)
                                let count = ribbons.filter { $0.category == category.rawValue }.count
                                let got = ribbons.filter { $0.category == category.rawValue && $0.isEarned }.count
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        shelf = active ? .all : .category(category)
                                    }
                                } label: {
                                    MicroLabel(text: "\(category.title) \(got)/\(count)", color: active ? Palette.ink : Palette.linen, size: 10)
                                        .padding(.horizontal, 12)
                                        .frame(minHeight: 36)
                                        .background(Capsule().fill(active ? Palette.sun500 : Palette.blue900.opacity(0.85)))
                                        .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: 2))
                                }
                                .buttonStyle(ArtPressStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if shown.isEmpty {
                        EdgeStateCard(art: shelf == .earned ? "ribbon_badge_locked" : "ribbon_badge",
                                      title: shelf == .earned ? "No ribbons pinned yet" : "All pinned",
                                      message: shelf == .earned ? "Sow your first field to pin the First Furrow ribbon."
                                                                : "Every ribbon on this shelf is already on the door.") {
                            EmptyView()
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 18) {
                        ForEach(Array(shown.enumerated()), id: \.element.objectID) { index, ribbon in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedKey = ribbon.key
                                }
                            } label: {
                                VStack(spacing: -6) {
                                    Rosette(earned: ribbon.isEarned, size: 60)
                                        .sway(ribbon.isEarned ? 4 : 1.5, period: 2.2 + Double(index % 4) * 0.3,
                                              anchor: .top, phase: Double(index % 5) * 0.2)
                                    Text(ribbon.title ?? "")
                                        .font(Typo.heavy(10))
                                        .tracking(1.2)
                                        .textCase(.uppercase)
                                        .foregroundColor(ribbon.isEarned ? Palette.ink : Palette.linen)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .padding(.horizontal, 6)
                                        .frame(maxWidth: .infinity, minHeight: 26)
                                        .background(RoundedRectangle(cornerRadius: 9).fill(ribbon.isEarned ? Palette.sun500 : Palette.blue700))
                                        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Palette.ink, lineWidth: 2.5))
                                        .shadow(color: ribbon.isEarned ? Palette.plankUnder : Palette.blue950, radius: 0, x: 0, y: 3)
                                }
                                .opacity(ribbon.isEarned ? 1 : 0.86)
                                .rotationEffect(.degrees([-3, 2, -1, 3, -2, 1][index % 6]))
                                .overlay(alignment: .top) {
                                    if selectedKey == ribbon.key {
                                        Circle().fill(Palette.stitchRed).frame(width: 12, height: 12)
                                            .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2))
                                            .offset(y: -6)
                                    }
                                }
                            }
                            .buttonStyle(ArtPressStyle())
                            .entrance(2 + index % 6)
                            .accessibilityLabel("\(ribbon.title ?? ""), \(ribbon.isEarned ? "earned" : "not yet earned")")
                        }
                    }
                    .padding(.top, 6)
                }
                .screenPadding()
            }

            TopStitchBand()
        }
    }

    private func spotlightCard(_ ribbon: RibbonEntity, isNewest: Bool, earnedCount: Int) -> some View {
        LinenCard(padding: Space.s2) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Rosette(earned: ribbon.isEarned, size: 76, hero: ribbon.isEarned)
                        .sway(5, period: 2.4)
                    VStack(alignment: .leading, spacing: 4) {
                        MicroLabel(text: isNewest ? "Newest ribbon" : (ribbon.isEarned ? "Earned" : "Still to earn"),
                                   color: Palette.stitchRed)
                        Text(ribbon.title ?? "")
                            .font(Typo.heavy(24))
                            .foregroundColor(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(ribbon.detail ?? "")
                            .font(Typo.medium(14))
                            .foregroundColor(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        if !ribbon.isEarned {
                            MicroLabel(text: "\(Format.number(Int(ribbon.progress))) / \(Format.number(Int(ribbon.goal)))",
                                       color: Palette.ink)
                        }
                    }
                }
                HStack(spacing: 10) {
                    StripedBar(value: ribbon.isEarned ? Double(earnedCount) / Double(max(1, ribbons.count)) : Double(ribbon.progress) / Double(max(1, ribbon.goal)),
                               height: 12)
                    MicroLabel(text: ribbon.isEarned ? "\(earnedCount)/\(ribbons.count)" : "\(Int(Double(ribbon.progress) / Double(max(1, ribbon.goal)) * 100))%",
                               color: Palette.inkSoft)
                }
            }
        }
        .padding(.top, 10)
    }
}
