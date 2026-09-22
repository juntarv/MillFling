import SwiftUI

/// Chart colours, validated with the dataviz palette validator on the linen card surface (#FFF6E4):
/// cobalt #1763DE (single-series hue) + slate #7486A3 (de-emphasis) — both >= 3:1 contrast,
/// CVD separation ΔE 15.7, normal-vision ΔE 17.4. Text never wears these; it stays in ink tokens.
enum ChartInk {
    static let series = Palette.blue700
    static let muted = Color(hex: 0x7486A3)
    static let grid = Palette.ink.opacity(0.12)
}

struct ChartDatum: Identifiable, Equatable {
    let id: String
    /// Short axis / row label.
    let label: String
    let value: Double
    /// De-emphasised mark (e.g. a fallow run) — drawn in slate.
    var muted: Bool = false
    /// Callout text when the mark is selected.
    var detail: String = ""
    /// Optional art shown at the start of a row (identity by art, never by colour).
    var icon: String? = nil
}

/// Column mark: square at the baseline, 4 pt rounded data end.
struct TopRoundedBar: Shape {
    var radius: CGFloat = 4
    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 2, rect.height)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Bar mark for horizontal rows: square at the leading baseline, 4 pt rounded data end.
struct EndRoundedBar: Shape {
    var radius: CGFloat = 4
    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height / 2, rect.width)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

enum ChartScale {
    /// Clean axis maximum (1, 2, 2.5, 5 × 10ⁿ) at or above the data.
    static func niceMax(_ value: Double) -> Double {
        guard value > 0 else { return 1 }
        let magnitude = pow(10, floor(log10(value)))
        let f = value / magnitude
        let nice: Double = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 2.5 ? 2.5 : (f <= 5 ? 5 : 10)))
        return nice * magnitude
    }
}

/// Two-series key (never colour alone: swatch + ink label).
struct ChartLegend: View {
    let items: [(String, Color)]
    var body: some View {
        HStack(spacing: Space.s2) {
            ForEach(items.indices, id: \.self) { i in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(items[i].1).frame(width: 12, height: 12)
                    MicroLabel(text: items[i].0, color: Palette.inkSoft, size: 9)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Column chart over time: hairline grid, clean ticks, one callout value (latest, or the tapped column).
struct ColumnChart: View {
    let data: [ChartDatum]
    var height: CGFloat = 150
    var format: (Double) -> String = { Format.number(Int($0.rounded())) }
    @Environment(\.motionEnabled) private var motion
    @State private var grown = false
    @State private var selected: String?

    var body: some View {
        let top = ChartScale.niceMax(data.map(\.value).max() ?? 0)
        let pick = data.first { $0.id == selected } ?? data.last
        VStack(alignment: .leading, spacing: Space.s1) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let pick {
                    RollingText(text: format(pick.value))
                        .font(Typo.thin(28))
                        .foregroundColor(Palette.ink)
                    MicroLabel(text: pick.detail.isEmpty ? pick.label : pick.detail, color: Palette.inkSoft, size: 9)
                }
                Spacer(minLength: 4)
                MicroLabel(text: selected == nil ? "Latest · tap a bar" : "Selected", color: Palette.inkSoft, size: 8.5)
            }
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(format(top))
                    Spacer(minLength: 0)
                    Text(format(top / 2))
                    Spacer(minLength: 0)
                    Text("0")
                }
                .font(Typo.heavy(9))
                .foregroundColor(Palette.inkSoft)
                .monospacedDigit()
                .frame(minWidth: 30, alignment: .trailing)
                .frame(height: height)
                .accessibilityHidden(true)

                GeometryReader { geo in
                    let count = max(1, data.count)
                    let slot = geo.size.width / CGFloat(count)
                    let barWidth = min(24, max(4, slot - 2))
                    ZStack(alignment: .bottomLeading) {
                        VStack(spacing: 0) {
                            Rectangle().fill(ChartInk.grid).frame(height: 1)
                            Spacer(minLength: 0)
                            Rectangle().fill(ChartInk.grid).frame(height: 1)
                            Spacer(minLength: 0)
                            Rectangle().fill(Palette.ink.opacity(0.3)).frame(height: 1)
                        }
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(data) { d in
                                let fraction = CGFloat(d.value / top) * (grown || !motion ? 1 : 0.02)
                                Button {
                                    Haptics.shared.tap()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selected = selected == d.id ? nil : d.id
                                    }
                                } label: {
                                    VStack(spacing: 0) {
                                        Spacer(minLength: 0)
                                        TopRoundedBar(radius: 4)
                                            .fill(d.muted ? ChartInk.muted : ChartInk.series)
                                            .frame(width: barWidth, height: max(2, geo.size.height * fraction))
                                            .opacity(selected == nil || selected == d.id ? 1 : 0.4)
                                    }
                                    .frame(width: slot, height: geo.size.height)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(RowPressStyle())
                                .accessibilityLabel("\(d.detail.isEmpty ? d.label : d.detail): \(format(d.value))")
                            }
                        }
                    }
                }
                .frame(height: height)
            }
            if let first = data.first, let last = data.last {
                HStack {
                    MicroLabel(text: first.label, color: Palette.inkSoft, size: 8.5)
                    Spacer()
                    MicroLabel(text: last.label, color: Palette.inkSoft, size: 8.5)
                }
                .padding(.leading, 36)
            }
        }
        .onAppear {
            if motion {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.82).delay(0.25)) { grown = true }
            } else {
                grown = true
            }
        }
    }
}

/// Horizontal bars for comparing magnitude across named rows; value at the bar tip.
struct BarRowsChart: View {
    let data: [ChartDatum]
    var maxValue: Double? = nil
    var labelWidth: CGFloat = 104
    var valueText: (ChartDatum) -> String = { Format.number(Int($0.value.rounded())) }
    @Environment(\.motionEnabled) private var motion
    @State private var grown = false

    var body: some View {
        let top = maxValue ?? ChartScale.niceMax(data.map(\.value).max() ?? 0)
        VStack(spacing: Space.s1) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, d in
                HStack(spacing: Space.s1) {
                    if let icon = d.icon {
                        Art(icon).frame(width: 24, height: 24)
                    }
                    Text(d.label)
                        .font(Typo.heavy(12))
                        .foregroundColor(d.muted ? Palette.inkSoft : Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: labelWidth, alignment: .leading)
                    GeometryReader { geo in
                        let fraction = CGFloat(d.value / max(top, 0.0001)) * (grown || !motion ? 1 : 0.02)
                        ZStack(alignment: .leading) {
                            Rectangle().fill(ChartInk.grid).frame(width: 1)
                            EndRoundedBar(radius: 4)
                                .fill(d.muted ? ChartInk.muted : ChartInk.series)
                                .frame(width: max(2, (geo.size.width - 1) * fraction), height: 16)
                        }
                        .frame(maxHeight: .infinity)
                        .animation(motion ? .spring(response: 0.7, dampingFraction: 0.82).delay(0.08 * Double(index)) : nil,
                                   value: grown)
                    }
                    .frame(height: 22)
                    Text(valueText(d))
                        .font(Typo.heavy(12))
                        .foregroundColor(Palette.ink)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(minWidth: 44, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(d.label): \(valueText(d))")
            }
        }
        .onAppear {
            if motion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { grown = true }
            } else {
                grown = true
            }
        }
    }
}

/// Linen card holding one chart: title, one-line takeaway, the chart or its table.
struct ChartCard<Content: View>: View {
    let title: String
    let takeaway: String
    @ViewBuilder var content: Content

    var body: some View {
        LinenCard(padding: Space.s2) {
            VStack(alignment: .leading, spacing: Space.s1 + 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typo.heavy(17))
                        .foregroundColor(Palette.ink)
                    Text(takeaway)
                        .font(Typo.medium(13))
                        .foregroundColor(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
        }
    }
}

/// Table view of a chart's data — every value readable without colour.
struct ChartTable: View {
    let data: [ChartDatum]
    var valueText: (ChartDatum) -> String = { Format.number(Int($0.value.rounded())) }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, d in
                HStack {
                    Text(d.detail.isEmpty ? d.label : d.detail)
                        .font(Typo.medium(13))
                        .foregroundColor(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer()
                    Text(valueText(d))
                        .font(Typo.heavy(13))
                        .foregroundColor(Palette.ink)
                        .monospacedDigit()
                }
                .padding(.vertical, 6)
                if index < data.count - 1 { Rectangle().fill(ChartInk.grid).frame(height: 1) }
            }
        }
    }
}
