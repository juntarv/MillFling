import CoreGraphics

/// Perspective plot grid on the ground plane: row 0 is the far row next to the mill,
/// nearer rows are taller and wider. Pure geometry — used by the scene to draw and hit-test.
struct FieldGeometry: Equatable {
    struct Hit: Equatable {
        let row: Int
        let col: Int
        let index: Int
        /// 0 at the plot centre, ~1 at its edge.
        let centreDistance: CGFloat
    }

    let rows: Int
    let cols: Int
    let top: CGFloat
    let bottom: CGFloat
    let centerX: CGFloat
    let farHalfWidth: CGFloat
    let nearHalfWidth: CGFloat
    let gap: CGFloat
    private let rowEdges: [CGFloat]   // rows + 1 values from top down

    init(rows: Int, cols: Int, top: CGFloat, bottom: CGFloat, centerX: CGFloat,
         farHalfWidth: CGFloat, nearHalfWidth: CGFloat, gap: CGFloat) {
        self.rows = rows
        self.cols = cols
        self.top = top
        self.bottom = bottom
        self.centerX = centerX
        self.farHalfWidth = farHalfWidth
        self.nearHalfWidth = nearHalfWidth
        self.gap = gap
        let weights = (0..<rows).map { 1 + 0.2 * CGFloat($0) }
        let total = weights.reduce(0, +)
        var edges: [CGFloat] = [top]
        var y = top
        for w in weights {
            y -= (top - bottom) * w / total
            edges.append(y)
        }
        rowEdges = edges
    }

    static let empty = FieldGeometry(rows: 1, cols: 1, top: 1, bottom: 0, centerX: 0,
                                     farHalfWidth: 1, nearHalfWidth: 1, gap: 0)

    func rowTop(_ r: Int) -> CGFloat { rowEdges[r] + (r == 0 ? 0 : -gap * 0.5) }
    func rowBottom(_ r: Int) -> CGFloat { rowEdges[r + 1] + (r == rows - 1 ? 0 : gap * 0.5) }

    func halfWidth(atY y: CGFloat) -> CGFloat {
        let t = max(0, min(1, (top - y) / max(1, top - bottom)))
        return farHalfWidth + (nearHalfWidth - farHalfWidth) * t
    }

    private func columnSpan(col: Int, atY y: CGFloat) -> (CGFloat, CGFloat) {
        let hw = halfWidth(atY: y)
        let colWidth = (2 * hw - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let x0 = centerX - hw + CGFloat(col) * (colWidth + gap)
        return (x0, x0 + colWidth)
    }

    /// Corners: top-left, top-right, bottom-right, bottom-left.
    func quad(row: Int, col: Int) -> [CGPoint] {
        let yt = rowTop(row), yb = rowBottom(row)
        let (tl, tr) = columnSpan(col: col, atY: yt)
        let (bl, br) = columnSpan(col: col, atY: yb)
        return [CGPoint(x: tl, y: yt), CGPoint(x: tr, y: yt), CGPoint(x: br, y: yb), CGPoint(x: bl, y: yb)]
    }

    func center(row: Int, col: Int) -> CGPoint {
        let y = (rowTop(row) + rowBottom(row)) / 2
        let (a, b) = columnSpan(col: col, atY: y)
        return CGPoint(x: (a + b) / 2, y: y)
    }

    func plotSize(row: Int, col: Int) -> CGSize {
        let y = (rowTop(row) + rowBottom(row)) / 2
        let (a, b) = columnSpan(col: col, atY: y)
        return CGSize(width: b - a, height: rowTop(row) - rowBottom(row))
    }

    func hitTest(_ p: CGPoint) -> Hit? {
        guard p.y <= top, p.y >= bottom else { return nil }
        var row = -1
        for r in 0..<rows where p.y <= rowTop(r) && p.y >= rowBottom(r) {
            row = r
            break
        }
        guard row >= 0 else { return nil }
        for c in 0..<cols {
            let (a, b) = columnSpan(col: c, atY: p.y)
            if p.x >= a && p.x <= b {
                let cx = (a + b) / 2
                let cy = (rowTop(row) + rowBottom(row)) / 2
                let dx = (p.x - cx) / max(1, (b - a) / 2)
                let dy = (p.y - cy) / max(1, (rowTop(row) - rowBottom(row)) / 2)
                return Hit(row: row, col: c, index: row * cols + c, centreDistance: (dx * dx + dy * dy).squareRoot())
            }
        }
        return nil
    }
}
