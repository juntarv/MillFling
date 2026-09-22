import SwiftUI

/// Dormant loader screen in the Embroidered Sunfield style. Self-contained and intentionally
/// not referenced by the launch flow — the release team wires it up.
struct SplashView: View {
    @Environment(\.motionEnabled) private var motion
    @State private var turning = false
    @State private var progress: CGFloat = 0.08
    @State private var cloudDrift = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / 390, geo.size.height / 844)
            ZStack {
                ArtBackdrop(image: "bg_splash", wash: 0.15)

                Art("cloud_puff")
                    .frame(width: 110 * s)
                    .position(x: geo.size.width * 0.28 + (cloudDrift ? 16 : -10), y: geo.size.height * 0.1)
                Art("cloud_puff")
                    .frame(width: 124 * s)
                    .opacity(0.9)
                    .position(x: geo.size.width * 0.78 + (cloudDrift ? -14 : 10), y: geo.size.height * 0.22)

                VStack(spacing: 28 * s) {
                    Art(UIImage.exists("logo_title") ? "logo_title" : "logo_lockup")
                        .frame(width: min(geo.size.width - 40, 342 * s))
                        .rotationEffect(.degrees(-3))
                        .shadow(color: Palette.blue950.opacity(0.55), radius: 0, x: 0, y: 6)
                        .shadow(color: Palette.blue950.opacity(0.35), radius: 14, x: 0, y: 10)

                    ZStack {
                        Circle()
                            .stroke(Palette.blue900.opacity(0.6), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Palette.sun500, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Art("mill_sails")
                            .padding(16)
                            .rotationEffect(.degrees(turning ? -360 : 0))
                    }
                    .frame(width: 112 * s, height: 112 * s)

                    SkyPill(text: "Waking the sails")
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.46)

                TopStitchBand()
                VStack {
                    Spacer()
                    StitchBand()
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            guard motion else {
                progress = 0.92
                return
            }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { turning = true }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { progress = 0.92 }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { cloudDrift = true }
        }
    }
}
