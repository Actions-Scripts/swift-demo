import Foundation

/// Renders ASCII-art graphs of mathematical functions in the terminal.
public struct GraphPlotter {

    public struct PlotConfig {
        public var width: Int
        public var height: Int
        public var xMin: Double
        public var xMax: Double
        public var yMin: Double?   // nil = auto
        public var yMax: Double?   // nil = auto
        public var title: String?
        public var xLabel: String
        public var yLabel: String

        public init(
            width: Int = 80,
            height: Int = 24,
            xMin: Double = -10,
            xMax: Double = 10,
            yMin: Double? = nil,
            yMax: Double? = nil,
            title: String? = nil,
            xLabel: String = "x",
            yLabel: String = "y"
        ) {
            self.width = max(20, width)
            self.height = max(6, height)
            self.xMin = xMin
            self.xMax = xMax
            self.yMin = yMin
            self.yMax = yMax
            self.title = title
            self.xLabel = xLabel
            self.yLabel = yLabel
        }
    }

    public struct PlotSeries {
        public let name: String
        public let symbol: Character
        public let function: (Double) -> Double?

        public init(name: String, symbol: Character = "*", function: @escaping (Double) -> Double?) {
            self.name = name
            self.symbol = symbol
            self.function = function
        }
    }

    // MARK: - Public API

    /// Plot one or more function series and return the rendered ASCII string.
    public static func plot(series: [PlotSeries], config: PlotConfig = PlotConfig()) -> String {
        guard !series.isEmpty else { return "(nothing to plot)" }
        let xStep = (config.xMax - config.xMin) / Double(config.width - 1)

        // Sample all series to find y range
        var allY: [Double] = []
        let samples: [[(x: Double, y: Double?)]] = series.map { s in
            (0..<config.width).map { col in
                let x = config.xMin + Double(col) * xStep
                return (x, s.function(x))
            }
        }
        for s in samples {
            allY.append(contentsOf: s.compactMap { $0.y }.filter { $0.isFinite })
        }

        let yMin = config.yMin ?? (allY.min() ?? -1)
        let yMax = config.yMax ?? (allY.max() ?? 1)
        let yRange = yMax == yMin ? 2.0 : yMax - yMin

        // Build grid
        var grid = [[Character]](
            repeating: [Character](repeating: " ", count: config.width),
            count: config.height
        )

        // Draw axes
        let xAxisRow = rowForY(y: 0, yMin: yMin, yRange: yRange, height: config.height)
        let yAxisCol = colForX(x: 0, xMin: config.xMin, xMax: config.xMax, width: config.width)

        if let r = xAxisRow { for c in 0..<config.width { grid[r][c] = "─" } }
        if let c = yAxisCol { for r in 0..<config.height { grid[r][c] = "│" } }
        if let r = xAxisRow, let c = yAxisCol { grid[r][c] = "┼" }

        // Plot each series
        for (idx, s) in series.enumerated() {
            let sym = s.symbol
            for col in 0..<config.width {
                if let y = samples[idx][col].y, y.isFinite {
                    if let row = rowForY(y: y, yMin: yMin, yRange: yRange, height: config.height) {
                        grid[row][col] = sym
                    }
                }
            }
        }

        // Render to string
        var lines: [String] = []

        // Title
        if let title = config.title {
            lines.append(title.centered(width: config.width + 10))
        }

        // Y-axis label + plot rows
        for (row, cells) in grid.enumerated() {
            let yVal = yMax - Double(row) * yRange / Double(config.height - 1)
            let yTag = row == 0 ? String(format: "%6.2f", yVal)
                     : row == config.height - 1 ? String(format: "%6.2f", yVal)
                     : row == config.height / 2 ? String(format: "%6.2f", yVal)
                     : "      "
            lines.append("\(yTag) \(String(cells))")
        }

        // X-axis tick marks
        let xTicks = buildXTicks(xMin: config.xMin, xMax: config.xMax, width: config.width)
        lines.append("       " + xTicks)
        lines.append("       \(config.xLabel.centered(width: config.width))")

        // Legend
        if series.count > 1 {
            lines.append("")
            lines.append("Legend:")
            for s in series { lines.append("  \(s.symbol) = \(s.name)") }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func rowForY(y: Double, yMin: Double, yRange: Double, height: Int) -> Int? {
        let frac = (y - yMin) / yRange
        guard frac >= 0 && frac <= 1 else { return nil }
        let row = height - 1 - Int(frac * Double(height - 1))
        return max(0, min(height - 1, row))
    }

    private static func colForX(x: Double, xMin: Double, xMax: Double, width: Int) -> Int? {
        let frac = (x - xMin) / (xMax - xMin)
        guard frac >= 0 && frac <= 1 else { return nil }
        return max(0, min(width - 1, Int(frac * Double(width - 1))))
    }

    private static func buildXTicks(xMin: Double, xMax: Double, width: Int) -> String {
        var chars = [Character](repeating: " ", count: width)
        let tickValues = stride(from: ceil(xMin), through: floor(xMax), by: max(1, (xMax - xMin) / 8))
        for x in tickValues {
            let frac = (x - xMin) / (xMax - xMin)
            let col = Int(frac * Double(width - 1))
            if col >= 0 && col < width { chars[col] = "┬" }
        }
        return String(chars)
    }
}

// MARK: - String helpers

private extension String {
    func centered(width: Int) -> String {
        guard count < width else { return self }
        let pad = (width - count) / 2
        return String(repeating: " ", count: pad) + self
    }
}
