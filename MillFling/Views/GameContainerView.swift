import SwiftUI
import SpriteKit

/// Hosts the single SpriteView (scene owned by the view model) with SwiftUI overlays on top.
struct GameContainerView: View {
    @ObservedObject var vm: GameViewModel
    let onFieldMap: () -> Void
    let onMenu: () -> Void
    let onPlayField: (Int) -> Void
    let onDaily: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(scene: vm.scene, preferredFramesPerSecond: 60)
                    .ignoresSafeArea()

                // navy scrim behind the status bar so the light status text reads over bright sky art
                VStack(spacing: 0) {
                    LinearGradient(colors: [Palette.blue950.opacity(0.85), Palette.blue950.opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.safeAreaInsets.top + 18)
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

                HUDView(hud: vm.hud, demo: vm.isDemo, onPause: vm.pause)
                    .onPreferenceChange(HUDHeightKey.self) { vm.updateHUDReserve($0) }

                if vm.state == .paused {
                    PauseOverlay(hud: vm.hud,
                                 onResume: vm.resume,
                                 onRestart: vm.restart,
                                 onFieldMap: vm.field.isDaily ? onDaily : onFieldMap,
                                 onMenu: onMenu,
                                 mapLabel: vm.field.isDaily ? "Daily page" : "Field map")
                        .transition(.opacity)
                }

                if vm.state.isFinished, let report = vm.report {
                    HarvestReportView(report: report,
                                      onNext: { onPlayField(report.fieldIndex + 1) },
                                      onReplay: vm.restart,
                                      onFieldMap: onFieldMap,
                                      onDaily: onDaily)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.state)
            .onAppear { vm.updateInsets(top: geo.safeAreaInsets.top, bottom: geo.safeAreaInsets.bottom) }
            .onChange(of: geo.safeAreaInsets) { insets in
                vm.updateInsets(top: insets.top, bottom: insets.bottom)
            }
        }
        .onChange(of: vm.state) { newState in
            vm.scene.isPaused = newState != .playing
        }
    }
}

// MARK: - HUD

/// Bottom edge of the HUD's rows, measured from the top safe inset.
struct HUDHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct HUDView: View {
    let hud: HUDState
    let demo: Bool
    let onPause: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                LinenCard(padding: 12) {
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 0) {
                                MicroLabel(text: "Score", color: Palette.inkSoft)
                                Text(Format.number(hud.score))
                                    .font(Typo.thin(34))
                                    .foregroundColor(Palette.ink)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 0) {
                                MicroLabel(text: "Plots", color: Palette.inkSoft)
                                HStack(alignment: .firstTextBaseline, spacing: 1) {
                                    Text("\(hud.plotsSown)")
                                        .font(Typo.thin(34))
                                        .contentTransition(.numericText())
                                    Text("/\(hud.quota)").font(Typo.thin(18))
                                }
                                .foregroundColor(Palette.ink)
                                .monospacedDigit()
                                .lineLimit(1)
                            }
                        }
                        StripedBar(value: Double(hud.plotsSown) / Double(max(1, hud.quota)), height: 11)
                    }
                    .padding(.horizontal, 2)
                }
                .allowsHitTesting(false)

                LinenIconButton(systemName: "pause.fill", size: 56, action: onPause)
                    .accessibilityLabel("Pause")
            }
            .entrance(0)

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Art("windvane_icon")
                        .frame(width: 22, height: 22)
                        .scaleEffect(x: hud.wind < 0 ? -1 : 1, y: 1)
                        .accessibilityLabel("Wind")
                    MicroLabel(text: Format.wind(hud.wind), color: Palette.linen)
                        .fixedSize()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    ZStack {
                        Capsule().fill(Palette.blue950.opacity(0.7)).offset(y: 4)
                        Capsule().fill(LinearGradient(colors: [Palette.blue700, Palette.blue900], startPoint: .top, endPoint: .bottom))
                        Capsule().strokeBorder(Palette.ink, lineWidth: 3)
                    }
                )
                .layoutPriority(1)

                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    MicroLabel(text: "Pods", color: Palette.linen)
                        .fixedSize()
                        .readableOnArt()
                    ForEach(0..<min(hud.podsLeft, 6), id: \.self) { _ in
                        Ellipse().fill(Palette.linen)
                            .overlay(Ellipse().strokeBorder(Palette.ink, lineWidth: 2.2))
                            .frame(width: 16, height: 12)
                            .transition(.scale(scale: 0.2).combined(with: .opacity))
                    }
                    if hud.podsLeft > 6 {
                        MicroLabel(text: "+\(hud.podsLeft - 6)", color: Palette.linen)
                            .fixedSize()
                            .readableOnArt()
                    }
                    if hud.podsLeft == 0 {
                        MicroLabel(text: "none", color: Palette.sun300).readableOnArt()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.blue950.opacity(0.45)))
            }
            .allowsHitTesting(false)

            HStack(spacing: 8) {
            if hud.streak >= 2 {
                HStack(spacing: 8) {
                    MicroLabel(text: "Streak")
                    Text("x\(hud.streak)")
                        .font(Typo.thin(22))
                        .foregroundColor(Palette.ink)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Palette.plankUnder).offset(y: 4)
                        RoundedRectangle(cornerRadius: 10).fill(Palette.sun500)
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink, lineWidth: 3)
                    }
                )
                .rotationEffect(.degrees(-2))
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
            }
            if hud.goldenLeft > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Palette.sun300)
                    MicroLabel(text: "\(hud.goldenLeft) golden", color: Palette.linen)
                        .fixedSize()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.blue950.opacity(0.6)))
                .overlay(Capsule().strokeBorder(Palette.sun300, lineWidth: 2))
                .allowsHitTesting(false)
            }
            }
            .frame(height: 38, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: HUDHeightKey.self, value: proxy.frame(in: .named("hud")).maxY)
                }
            )

            Spacer()

            if hud.showHint && !demo {
                HStack {
                    Spacer()
                    SkyPill(text: hud.hintText)
                    Spacer()
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .coordinateSpace(name: "hud")
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hud.streak >= 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hud.podsLeft)
        .animation(.easeInOut(duration: 0.3), value: hud.showHint)
    }
}

// MARK: - Pause

struct PauseOverlay: View {
    @EnvironmentObject private var store: FarmStore
    let hud: HUDState
    let onResume: () -> Void
    let onRestart: () -> Void
    let onFieldMap: () -> Void
    let onMenu: () -> Void
    var mapLabel: String = "Field map"

    var body: some View {
        ZStack {
            Palette.blue950.opacity(0.46).ignoresSafeArea()
                .onTapGesture {
                    Haptics.shared.tap()
                    onResume()
                }
            ScrollView(showsIndicators: false) {
                LinenCard(padding: Space.s3) {
                    VStack(alignment: .leading, spacing: Space.s2) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                MicroLabel(text: "\(hud.title) · \(hud.regionName)", color: Palette.stitchRed)
                                Text("Sails held")
                                    .font(Typo.heavy(Typo.titleSize))
                                    .foregroundColor(Palette.ink)
                                    .minimumScaleFactor(0.75)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Art("pause_mark").frame(width: 44, height: 50).breathe(0.06)
                        }
                        HStack(spacing: 10) {
                            well("\(Format.number(hud.score))", "score").layoutPriority(1)
                            well("\(hud.plotsSown)/\(hud.quota)", "plots")
                            well("\(hud.podsLeft)", "pods")
                        }
                        Button(action: onResume) { Text("RESUME") }
                            .buttonStyle(PlankButtonStyle(fontSize: 24))
                            .breathe(0.02)
                            .padding(.top, 4)
                        HStack(spacing: 12) {
                            Button("Restart", action: onRestart).buttonStyle(BluePlateButtonStyle())
                            Button(mapLabel, action: onFieldMap).buttonStyle(BluePlateButtonStyle())
                        }
                        Button("Mill Hill", action: onMenu).buttonStyle(BluePlateButtonStyle())
                        Toggle(isOn: Binding(get: { store.preference.hapticsOn }, set: { store.setHaptics($0) })) {
                            MicroLabel(text: "Haptics", color: Palette.inkSoft)
                        }
                        .toggleStyle(FolkToggleStyle())
                    }
                }
                .entrance(0)
                .padding(.horizontal, Space.s3)
                .padding(.vertical, Space.s5)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func well(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            RollingText(text: value)
                .font(Typo.thin(26))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            MicroLabel(text: label, color: Palette.inkSoft)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink.opacity(0.25), lineWidth: 2))
    }
}
