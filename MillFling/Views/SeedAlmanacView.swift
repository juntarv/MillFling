import SwiftUI

struct SeedAlmanacView: View {
    @EnvironmentObject private var store: FarmStore
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SeedEntity.sortIndex, ascending: true)])
    private var seeds: FetchedResults<SeedEntity>

    enum Shelf: Hashable { case all, ready, locked }

    let onBack: () -> Void
    let onSeed: (String) -> Void
    @State private var featuredKey: String?
    @State private var shelf: Shelf = .all

    var body: some View {
        let _ = store.revision
        let selected = store.selectedSeed.key
        let featured = seeds.first { $0.key == (featuredKey ?? selected) } ?? seeds.first
        let unlockedCount = seeds.filter(\.isUnlocked).count
        let rest = seeds.filter { seed in
            guard seed.key != featured?.key else { return false }
            switch shelf {
            case .all: return true
            case .ready: return seed.isUnlocked
            case .locked: return !seed.isUnlocked
            }
        }

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_almanac", wash: 0.25)
            AmbientMotes(count: 12, color: Palette.sun100).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: "\(unlockedCount) of \(SeedCatalog.all.count) varieties unlocked", title: "Seed Almanac", onBack: onBack)
                        .entrance(0)

                    if unlockedCount == SeedCatalog.all.count {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(Palette.leaf)
                            Text("Every variety is in the crate. Pick the seed that suits the field.")
                                .font(Typo.heavy(13))
                                .foregroundColor(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinenSurface(radius: 14))
                    }

                    if let featured {
                        FeaturedSeedCard(seed: featured, inHopper: featured.key == selected, onKeep: {
                            if let key = featured.key { store.selectSeed(key) }
                        }, onPage: {
                            onSeed(featured.key ?? SeedCatalog.defaultKey)
                        })
                        .padding(.top, Space.s1)
                        .id(featured.objectID)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .entrance(1)
                    }

                    SectionHeader(title: "The rest of the crate", trailing: "\(rest.count)")

                    StitchSegments(options: [(Shelf.all, "All \(SeedCatalog.all.count)"),
                                             (Shelf.ready, "Ready \(unlockedCount)"),
                                             (Shelf.locked, "Locked \(SeedCatalog.all.count - unlockedCount)")],
                                   selection: $shelf)

                    if rest.isEmpty {
                        EdgeStateCard(art: "crate_seeds",
                                      title: shelf == .locked ? "Nothing left to unlock" : "Only one seed so far",
                                      message: shelf == .locked ? "Nothing locked — every variety is ready in the crate. Happy sowing!"
                                                                : "Just the one seed for now. Sow more fields and new varieties will arrive in the crate.") {
                            EmptyView()
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                        ForEach(rest, id: \.objectID) { seed in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { featuredKey = seed.key }
                            } label: {
                                SeedCard(seed: seed, inHopper: seed.key == selected)
                            }
                            .buttonStyle(ArtPressStyle())
                            .entrance(3 + (rest.firstIndex(of: seed) ?? 0) % 6)
                        }
                    }
                }
                .screenPadding()
            }

            TopStitchBand()
        }
    }
}

private struct FeaturedSeedCard: View {
    let seed: SeedEntity
    let inHopper: Bool
    let onKeep: () -> Void
    let onPage: () -> Void

    var body: some View {
        let variety = SeedCatalog.variety(seed.key)
        ZStack(alignment: .topTrailing) {
            LinenCard(padding: Space.s2) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 14) {
                        SeedArt(key: seed.key ?? "rye", size: 72, locked: !seed.isUnlocked)
                            .bob(3, period: 2)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.sun100))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.ink, lineWidth: 3))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(seed.name ?? "")
                                .font(Typo.heavy(26))
                                .foregroundColor(Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            MicroLabel(text: "\(variety.traitLine) · \(seed.seedsPerBurst) per burst", color: Palette.inkSoft)
                            Text(seed.lore ?? "")
                                .font(Typo.medium(14))
                                .foregroundColor(Palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.trailing, inHopper ? 24 : 0)
                    }
                    StatBar(label: "Mass", value: seed.mass)
                    StatBar(label: "Spread", value: Double(seed.seedsPerBurst) / 6)
                    StatBar(label: "Drift", value: seed.drift)
                    if let trait = variety.trait.summary {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles").foregroundColor(Palette.stitchRed)
                            Text(trait)
                                .font(Typo.heavy(13))
                                .foregroundColor(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 2)
                    }
                    if seed.timesUsed > 0 {
                        HStack(spacing: 8) {
                            StatWell(value: "\(seed.plotsSown)", label: "plots sown", size: 20)
                            StatWell(value: Format.number(Int(seed.bestScore)), label: "best score", size: 20)
                        }
                    }
                    HStack(spacing: 8) {
                        if seed.isUnlocked {
                            Button(action: onKeep) {
                                Text(inHopper ? "IN THE HOPPER" : "PUT IN HOPPER")
                            }
                            .buttonStyle(PlankButtonStyle(fontSize: 13))
                            .disabled(inHopper)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill").foregroundColor(Palette.ink)
                                MicroLabel(text: "Sow field \(seed.unlockField) to unlock")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Palette.barBed))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 2.5))
                        }
                        VStack(spacing: 0) {
                            RollingText(text: "\(seed.timesUsed)")
                                .font(Typo.thin(22))
                                .foregroundColor(Palette.linen)
                            MicroLabel(text: "runs", color: Palette.sun300, size: 9)
                        }
                        .frame(width: 70, height: 50)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.blue900))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 3))
                        .accessibilityElement(children: .combine)
                    }
                    .padding(.top, 4)
                    Button(action: onPage) {
                        HStack(spacing: Space.s1) {
                            Image(systemName: "leaf.fill")
                            Text("OPEN SEED PAGE")
                        }
                    }
                    .buttonStyle(BluePlateButtonStyle())
                }
            }
            if inHopper {
                MicroLabel(text: "In the hopper", color: Palette.linen)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Palette.stitchRed))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink, lineWidth: 3))
                    .shadow(color: Palette.ink.opacity(0.4), radius: 0, x: 0, y: 4)
                    .rotationEffect(.degrees(4))
                    .offset(x: 6, y: -14)
            }
        }
    }
}

private struct StatBar: View {
    let label: String
    let value: Double
    var body: some View {
        HStack(spacing: 8) {
            MicroLabel(text: label, color: Palette.inkSoft)
                .frame(width: 64, alignment: .leading)
            StripedBar(value: value, height: 12)
        }
    }
}

private struct SeedCard: View {
    let seed: SeedEntity
    let inHopper: Bool

    var body: some View {
        let variety = SeedCatalog.variety(seed.key)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SeedArt(key: seed.key ?? "rye", size: 44, locked: !seed.isUnlocked)
                VStack(alignment: .leading, spacing: 3) {
                    Text(seed.name ?? "")
                        .font(Typo.heavy(15))
                        .foregroundColor(seed.isUnlocked ? Palette.ink : Palette.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    MicroLabel(text: seed.isUnlocked ? (inHopper ? "In hopper" : variety.traitLine) : "Field \(seed.unlockField)",
                               color: seed.isUnlocked ? Palette.inkSoft : Palette.lockedArt, size: 9)
                }
                Spacer(minLength: 0)
            }
            StripedBar(value: seed.isUnlocked ? Double(seed.seedsPerBurst) / 6 : 0.0, height: 9)
                .opacity(seed.isUnlocked ? 1 : 0.5)
        }
        .padding(12)
        .background(LinenSurface(radius: 16))
        .opacity(seed.isUnlocked ? 1 : 0.78)
    }
}
