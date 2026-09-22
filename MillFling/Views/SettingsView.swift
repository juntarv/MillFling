import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FarmStore
    let onBack: () -> Void
    let onAlmanac: () -> Void
    let onPaints: () -> Void
    let onGuide: () -> Void
    let onReplayTour: () -> Void
    let onResetDone: () -> Void

    @State private var confirmReset = false

    var body: some View {
        let _ = store.revision
        let seed = store.selectedSeed

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_settings", wash: 0.25)
            AmbientMotes(count: 12).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s3) {
                    ScreenHeader(kicker: "Mill Hill · offline", title: "Settings", onBack: onBack) {
                        Art("icon_settings").frame(width: 40, height: 40).sway(5, period: 2.4, anchor: .bottom)
                    }
                    .entrance(0)

                    SectionHeader(title: "Feel")

                    LinenCard(padding: Space.s2) {
                        VStack(spacing: 0) {
                            Toggle(isOn: Binding(get: { store.preference.hapticsOn }, set: { store.setHaptics($0) })) {
                                rowLabel("Haptics", "Taps on release, burst and sprout")
                            }
                            .toggleStyle(FolkToggleStyle())
                            .padding(.vertical, 8)
                            DashedRule(color: Palette.ink.opacity(0.35))
                            Toggle(isOn: Binding(get: { store.preference.animationsOn }, set: { store.setAnimations($0) })) {
                                rowLabel("Animations", "Screen shake, sail spin, score roll-up")
                            }
                            .toggleStyle(FolkToggleStyle())
                            .padding(.vertical, 8)
                        }
                    }
                    .entrance(1)

                    SectionHeader(title: "The farm")

                    LinenCard(padding: Space.s2) {
                        VStack(spacing: 0) {
                            Button(action: onAlmanac) {
                                HStack(spacing: 12) {
                                    SeedArt(key: seed.key, size: 34)
                                    rowLabel("Seed in the hopper", "\(seed.name) · \(seed.seedsPerBurst) seeds per burst")
                                    Spacer(minLength: 4)
                                    chevron
                                }
                                .frame(minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(RowPressStyle())
                            DashedRule(color: Palette.ink.opacity(0.35))
                            Button(action: onPaints) {
                                HStack(spacing: 12) {
                                    PaintedSails(paint: store.selectedPaint.color).frame(width: 34, height: 34)
                                    rowLabel("Mill paint", "\(store.selectedPaint.name) · \(store.paintEntities().filter(\.isUnlocked).count) of \(PaintCatalog.all.count) unlocked")
                                    Spacer(minLength: 4)
                                    chevron
                                }
                                .frame(minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(RowPressStyle())
                            DashedRule(color: Palette.ink.opacity(0.35))
                            Button(action: onGuide) {
                                HStack(spacing: 12) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Palette.blue700)
                                        .frame(width: 34, height: 34)
                                    rowLabel("Field guide", "Plots, hazards, wind and sowing skills")
                                    Spacer(minLength: 4)
                                    chevron
                                }
                                .frame(minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(RowPressStyle())
                            DashedRule(color: Palette.ink.opacity(0.35))
                            Button(action: onReplayTour) {
                                HStack(spacing: 12) {
                                    Art(UIImage.exists("icon_info") ? "icon_info" : "pod_seed").frame(width: 34, height: 34)
                                    rowLabel("Replay the three-step tour", "The release, burst and wind lessons again")
                                    Spacer(minLength: 4)
                                    chevron
                                }
                                .frame(minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(RowPressStyle())
                        }
                    }

                    .entrance(2)

                    SectionHeader(title: "Start over")

                    LinenCard(padding: Space.s2) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reset the whole farm")
                                .font(Typo.heavy(16))
                                .foregroundColor(Palette.ink)
                            Text("Clears all 72 fields, every ribbon, the almanac, daily streak, ranks, paints and the ledger, then walks you back through the tour.")
                                .font(Typo.medium(13))
                                .foregroundColor(Palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("Reset progress") { confirmReset = true }
                                .buttonStyle(RedPlateButtonStyle())
                                .padding(.top, 6)
                        }
                    }

                    HStack(spacing: 10) {
                        Art(UIImage.exists("icon_app_mark") ? "icon_app_mark" : "loader_sails").frame(width: 34, height: 34)
                        MicroLabel(text: "MillFling \(appVersion) · plays offline, always", color: Palette.linen, size: 10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Palette.blue950.opacity(0.66)))
                    .overlay(Capsule().strokeBorder(Palette.linen.opacity(0.5), lineWidth: 2))
                    .frame(maxWidth: .infinity)

                    HStack(alignment: .bottom) {
                        Art("sunflower_pair").frame(width: 70, height: 104)
                            .sway(3, period: 2.6, anchor: .bottom)
                        Spacer()
                        Art(UIImage.exists("hero_mill_noon") ? "hero_mill_noon" : "windmill_hero").frame(width: 110, height: 110)
                            .bob(3, period: 3)
                    }
                    .allowsHitTesting(false)
                }
                .screenPadding()
            }

            TopStitchBand()
        }
        .alert("Reset the whole farm?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) { confirmReset = false }
            Button("Reset", role: .destructive) {
                store.resetAll()
                Haptics.shared.enabled = store.preference.hapticsOn
                onResetDone()
            }
        } message: {
            Text("All fields, stars, ribbons, seed unlocks, paints, daily streaks and run history will be wiped. This cannot be undone.")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .black))
            .foregroundColor(Palette.ink)
    }

    private func rowLabel(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Typo.heavy(16))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            MicroLabel(text: subtitle, color: Palette.inkSoft, size: 9.5)
        }
    }
}
