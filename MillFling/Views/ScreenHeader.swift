import SwiftUI

/// Back plate + linen title card used at the top of every sub-screen.
struct ScreenHeader<Trailing: View>: View {
    let kicker: String
    let title: String
    let onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            LinenIconButton(systemName: "arrow.left", action: onBack)
                .accessibilityLabel("Back")
            LinenCard(padding: 10) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        MicroLabel(text: kicker, color: Palette.stitchRed)
                        Text(title)
                            .font(Typo.heavy(22))
                            .foregroundColor(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.leading, 4)
                    Spacer(minLength: 0)
                    trailing
                }
            }
        }
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(kicker: String, title: String, onBack: @escaping () -> Void) {
        self.kicker = kicker
        self.title = title
        self.onBack = onBack
        self.trailing = EmptyView()
    }
}
