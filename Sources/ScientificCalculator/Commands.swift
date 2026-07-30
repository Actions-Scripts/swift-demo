import ArgumentParser
import Foundation

// MARK: - calculate subcommand

struct Calculate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calculate",
        abstract: "Evaluate one or more mathematical expressions",
        aliases: ["calc", "eval"]
    )

    @Argument(help: "Mathematical expression(s) to evaluate, e.g. \"sin(pi/4) + log(e^2)\"")
    var expressions: [String] = []

    @Option(name: .shortAndLong, help: "Load configuration from YAML file")
    var config: String?

    @Flag(name: .shortAndLong, help: "Show step-by-step intermediate results")
    var verbose = false

    mutating func run() throws {
        let cfg = config.flatMap { try? AppConfig.load(fromFile: $0) } ?? AppConfig()
        let calc = Calculator()

        if expressions.isEmpty {
            // Interactive REPL mode
            print("Scientific Calculator  (type 'quit' to exit)")
            print("Functions: sin cos tan asin acos atan sinh cosh tanh exp log log2 log10")
            print("           sqrt cbrt pow abs ceil floor round factorial ncr npr")
            print("Constants: pi e tau phi")
            print("")
            while let line = readLine(strippingNewline: true) {
                let expr = line.trimmingCharacters(in: .whitespaces)
                guard !expr.isEmpty else { continue }
                if expr == "quit" || expr == "exit" { break }
                do {
                    let result = try calc.evaluate(expr)
                    let record = calc.history.last!
                    print("  = \(record.formattedResult)")
                    if verbose { print("    (raw: \(result))") }
                } catch {
                    print("  Error: \(error.localizedDescription)")
                }
            }
        } else {
            for expr in expressions {
                do {
                    let result = try calc.evaluate(expr)
                    let record = calc.history.last!
                    print("\(expr) = \(record.formattedResult)")
                    if verbose { print("  (raw Double: \(result))") }
                } catch {
                    print("\(expr) => Error: \(error.localizedDescription)")
                }
            }
        }

        // Optionally save history
        if cfg.enableHistory && !calc.history.isEmpty {
            let mgr = HistoryManager(directory: cfg.historyDirectory)
            let stamp = ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
            try? mgr.save(records: calc.history, toFile: "session-\(stamp).json")
        }
    }
}

// MARK: - graph subcommand

struct Graph: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "graph",
        abstract: "Plot a mathematical function as ASCII art"
    )

    @Argument(help: "Expression to plot as a function of x, e.g. \"sin(x)*exp(-x/4)\"")
    var expression: String

    @Option(name: .long, help: "Minimum x value")
    var xMin: Double = -10

    @Option(name: .long, help: "Maximum x value")
    var xMax: Double = 10

    @Option(name: .long, help: "Minimum y value (auto if omitted)")
    var yMin: Double?

    @Option(name: .long, help: "Maximum y value (auto if omitted)")
    var yMax: Double?

    @Option(name: .shortAndLong, help: "Plot width in characters")
    var width: Int = 80

    @Option(name: .shortAndLong, help: "Plot height in characters")
    var height: Int = 24

    @Option(name: .shortAndLong, help: "Load configuration from YAML file")
    var config: String?

    @Option(name: .long, help: "Second expression to overlay (optional)")
    var overlay: String?

    mutating func run() throws {
        let cfg = config.flatMap { try? AppConfig.load(fromFile: $0) } ?? AppConfig()
        let calc = Calculator()

        let plotConfig = GraphPlotter.PlotConfig(
            width:  cfg.graphWidth  != 80 ? cfg.graphWidth  : width,
            height: cfg.graphHeight != 24 ? cfg.graphHeight : height,
            xMin: xMin,
            xMax: xMax,
            yMin: yMin,
            yMax: yMax,
            title: expression,
            xLabel: "x",
            yLabel: "y"
        )

        // Capture expression strings by value so the escaping closures don't capture mutating self
        let exprString = expression
        let overlayString = overlay

        var seriesList: [GraphPlotter.PlotSeries] = [
            GraphPlotter.PlotSeries(name: exprString, symbol: "*") { x in
                // Substitute x in the expression by replacing the variable
                let exprWithX = exprString.replacingOccurrences(of: "x", with: "(\(x))")
                return try? calc.evaluate(exprWithX)
            }
        ]

        if let overlay = overlayString {
            seriesList.append(
                GraphPlotter.PlotSeries(name: overlay, symbol: "#") { x in
                    let exprWithX = overlay.replacingOccurrences(of: "x", with: "(\(x))")
                    return try? calc.evaluate(exprWithX)
                }
            )
        }

        let output = GraphPlotter.plot(series: seriesList, config: plotConfig)
        print(output)
    }
}

// MARK: - history subcommand

struct History: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "history",
        abstract: "Manage saved calculation history",
        subcommands: [HistoryList.self, HistoryLoad.self, HistoryExport.self]
    )
}

struct HistoryList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List saved history files"
    )

    @Option(name: .long, help: "Directory to search for history files")
    var directory: String?

    mutating func run() throws {
        let mgr = HistoryManager(directory: directory)
        let files = mgr.listSavedFiles()
        if files.isEmpty {
            print("No history files found.")
        } else {
            print("Saved history files:")
            for f in files { print("  \(f)") }
        }
    }
}

struct HistoryLoad: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "load",
        abstract: "Display contents of a history file"
    )

    @Argument(help: "History file name")
    var filename: String

    @Option(name: .long, help: "Directory containing history files")
    var directory: String?

    mutating func run() throws {
        let mgr = HistoryManager(directory: directory)
        let records = try mgr.load(fromFile: filename)
        print("Loaded \(records.count) record(s) from \(filename):")
        for (i, r) in records.enumerated() {
            print("  \(i + 1). \(r.expression) = \(r.formattedResult)")
        }
    }
}

struct HistoryExport: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export history to CSV"
    )

    @Argument(help: "Source history JSON file name")
    var filename: String

    @Option(name: .shortAndLong, help: "Output CSV path")
    var output: String = "history.csv"

    @Option(name: .long, help: "Directory containing history files")
    var directory: String?

    mutating func run() throws {
        let mgr = HistoryManager(directory: directory)
        let records = try mgr.load(fromFile: filename)
        try mgr.exportCSV(records: records, toPath: output)
        print("Exported \(records.count) record(s) to \(output)")
    }
}

// MARK: - configure subcommand

struct Configure: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "configure",
        abstract: "Show or validate a configuration file"
    )

    @Argument(help: "Path to YAML configuration file")
    var configFile: String?

    mutating func run() throws {
        if let path = configFile {
            let cfg = try AppConfig.load(fromFile: path)
            print("Configuration loaded from: \(path)")
            print("  graphWidth:       \(cfg.graphWidth)")
            print("  graphHeight:      \(cfg.graphHeight)")
            print("  defaultXMin:      \(cfg.defaultXMin)")
            print("  defaultXMax:      \(cfg.defaultXMax)")
            print("  precision:        \(cfg.precision)")
            print("  enableHistory:    \(cfg.enableHistory)")
            print("  historyDirectory: \(cfg.historyDirectory ?? "(default)")")
        } else {
            // Print sample config
            let sample = """
            # ScientificCalculator configuration
            graphWidth: 80
            graphHeight: 24
            defaultXMin: -10.0
            defaultXMax: 10.0
            precision: 6
            enableHistory: true
            # historyDirectory: /path/to/history
            # apiKey: your-key-here
            """
            print("Sample configuration (save as scalc.yaml):\n")
            print(sample)
        }
    }
}
