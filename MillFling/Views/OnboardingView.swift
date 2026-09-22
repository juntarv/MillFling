import SwiftUI

struct OnboardingView: View {
    let replay: Bool
    let onFinish: () -> Void
    @State private var page = 0

    private struct Step {
        let background: String
        let title: String
        let body: String
    }

    private let steps = [
        Step(background: "bg_onboarding", title: "Release on\nthe right beat",
             body: "A seed pod rides the turning sail. Tap once and it lets go on the tangent — wait a beat longer and the throw goes flatter and further."),
        Step(background: "bg_game", title: "Burst where\nthe plots are",
             body: "Tap again while the pod is in the air. It splits into a fan of seeds: burst early for a short scatter, late for a long one."),
        Step(background: "bg_field_rows", title: "Read the wind\nbefore you throw",
             body: "The vane and the drifting chaff show the wind. Light seeds bend with it, heavy ones drop straight. Crows and ponds eat what they catch.")
    ]

    var body: some View {
        ZStack {
            ArtBackdrop(image: steps[page].background, wash: 0.22)
                .animation(.easeInOut(duration: 0.35), value: page)
            AmbientMotes(count: 16, color: Palette.linen).ignoresSafeArea()

            GeometryReader { geo in
                let s = min(geo.size.width / 390, geo.size.height / 763)
                let artHeight = max(170, min(geo.size.height * 0.46, geo.size.height - 410 - Space.band))
                let artScale = min(s, artHeight / 320)
                VStack(spacing: 0) {
                    Color.clear.frame(height: Space.band)
                    TabView(selection: $page) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            illustration(i, scale: artScale)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: artHeight)

                    LinenCard(padding: Space.s3) {
                        VStack(alignment: .leading, spacing: 10) {
                            MicroLabel(text: "Step \(page + 1) of 3", color: Palette.stitchRed)
                            Text(steps[page].title)
                                .font(Typo.heavy(min(32, 32 * s)))
                                .foregroundColor(Palette.ink)
                                .lineSpacing(-2)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(steps[page].body)
                                .font(Typo.medium(min(Typo.bodySize, 17 * s)))
                                .foregroundColor(Palette.inkSoft)
                                .lineSpacing(2)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, Space.s3)
                    .animation(.easeInOut(duration: 0.25), value: page)
                    .entrance(1)

                    Spacer(minLength: Space.s1)

                    HStack(spacing: Space.s2) {
                        PageDots(count: steps.count, index: page)
                        Spacer()
                        Button {
                            if page < steps.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                            } else {
                                onFinish()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text(page < steps.count - 1 ? "NEXT" : (replay ? "BACK TO THE MILL" : "START SOWING"))
                                Image(systemName: "arrow.right").font(.system(size: 18, weight: .black))
                            }
                        }
                        .buttonStyle(PlankButtonStyle(fontSize: 20))
                        .frame(maxWidth: page < steps.count - 1 ? 170 : 250)
                        .breathe(0.02)
                    }
                    .padding(.horizontal, Space.s3)
                    .entrance(2)

                    Button(action: onFinish) {
                        SkyPill(text: replay ? "Close the tour" : "Skip the tour")
                    }
                    .buttonStyle(ArtPressStyle())
                    .frame(minHeight: 44)
                    .padding(.top, Space.s1)
                    .padding(.bottom, Space.s1)
                }
            }

            TopStitchBand()
        }
    }

    @ViewBuilder
    private func illustration(_ i: Int, scale s: CGFloat) -> some View {
        switch i {
        case 0:
            Art("ob_scene_release")
                .frame(width: 300 * s, height: 300 * s)
                .bob(5, period: 2.4)
        case 1:
            BurstIllustration(scale: s)
        default:
            WindIllustration(scale: s)
        }
    }
}

private struct PageDots: View {
    let count: Int
    let index: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Palette.sun500 : Palette.linen.opacity(0.55))
                    .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: 2.5))
                    .frame(width: i == index ? 30 : 13, height: 13)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
        .accessibilityLabel("Step \(index + 1) of \(count)")
    }
}

/// Step 2 art: the burst rosette, seed trails and plots, built from the harvested pieces.
private struct BurstIllustration: View {
    let scale: CGFloat
    @Environment(\.motionEnabled) private var motion
    @State private var pulse = false

    var body: some View {
        let s = scale
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 150 * s, y: 110 * s)); p.addQuadCurve(to: CGPoint(x: 70 * s, y: 250 * s), control: CGPoint(x: 100 * s, y: 170 * s))
                p.move(to: CGPoint(x: 150 * s, y: 110 * s)); p.addQuadCurve(to: CGPoint(x: 160 * s, y: 256 * s), control: CGPoint(x: 160 * s, y: 180 * s))
                p.move(to: CGPoint(x: 150 * s, y: 110 * s)); p.addQuadCurve(to: CGPoint(x: 250 * s, y: 246 * s), control: CGPoint(x: 220 * s, y: 170 * s))
            }
            .stroke(Palette.linen, style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round, dash: [1, 11 * s]))
            Art("pod_burst")
                .frame(width: 96 * s, height: 96 * s)
                .scaleEffect(pulse ? 1.08 : 0.94)
                .position(x: 150 * s, y: 104 * s)
            ForEach(0..<3, id: \.self) { i in
                Art("seed_single")
                    .frame(width: 22 * s, height: 22 * s)
                    .position(x: [70, 160, 250][i] * s, y: [244, 250, 240][i] * s)
            }
            Art("plot_sown").frame(width: 92 * s).position(x: 80 * s, y: 292 * s)
            Art("plot_bare").frame(width: 92 * s).position(x: 178 * s, y: 292 * s)
            Art("plot_sown").frame(width: 92 * s).position(x: 276 * s, y: 292 * s)
        }
        .frame(width: 330 * s, height: 330 * s)
        .onAppear {
            guard motion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

/// Step 3 art: the embroidered mill in a crosswind with a crow and drifting chaff.
private struct WindIllustration: View {
    let scale: CGFloat
    @Environment(\.motionEnabled) private var motion
    @State private var drift = false

    var body: some View {
        let s = scale
        ZStack {
            Art(UIImage.exists("hero_mill_noon") ? "hero_mill_noon" : "windmill_hero")
                .frame(width: 210 * s, height: 210 * s)
                .position(x: 110 * s, y: 190 * s)
            Art("cloud_puff").frame(width: 120 * s).position(x: 250 * s + (drift ? 18 * s : 0), y: 70 * s)
            ForEach(0..<5, id: \.self) { i in
                Capsule().fill(Palette.linen.opacity(0.8))
                    .frame(width: (18 + CGFloat(i % 3) * 6) * s, height: 4 * s)
                    .position(x: (190 + CGFloat(i) * 26) * s + (drift ? 24 * s : 0), y: (130 + CGFloat(i * 37 % 90)) * s)
            }
            Art("crow_hazard").frame(width: 88 * s).position(x: 262 * s, y: 170 * s)
            HStack(spacing: 8) {
                Art("windvane_icon").frame(width: 24, height: 24)
                MicroLabel(text: "Wind 2.4 E", color: Palette.linen)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(Palette.blue700))
            .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: 3))
            .position(x: 250 * s, y: 262 * s)
        }
        .frame(width: 330 * s, height: 330 * s)
        .onAppear {
            guard motion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}
