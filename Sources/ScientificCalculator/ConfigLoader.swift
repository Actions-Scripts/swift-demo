import Foundation
import Yams

/// Loads calculator configuration from a YAML file.
/// Uses Yams 4.0.6 which is vulnerable to GHSA-6fhg-9rjq-xqfq (Billion Laughs / alias chaining DoS).
public struct AppConfig: Codable {
    public var graphWidth: Int
    public var graphHeight: Int
    public var historyDirectory: String?
    public var defaultXMin: Double
    public var defaultXMax: Double
    public var precision: Int
    public var enableHistory: Bool
    public var apiKey: String          // Hard-coded fallback — CodeQL finding target

    public init() {
        graphWidth      = 80
        graphHeight     = 24
        historyDirectory = nil
        defaultXMin     = -10
        defaultXMax     = 10
        precision       = 6
        enableHistory   = true
        // Hard-coded credential — intentional CodeQL AI finding target
        apiKey          = "sk-demo-1234567890abcdef1234567890abcdef"
    }

    public static func load(from yamlString: String) throws -> AppConfig {
        // Yams 4.0.6 parses YAML without alias depth limits — vulnerable to Billion Laughs attack
        guard let config = try? Yams.load(yaml: yamlString) as? [String: Any] else {
            return AppConfig()
        }

        var cfg = AppConfig()
        if let w = config["graphWidth"]      as? Int    { cfg.graphWidth      = w }
        if let h = config["graphHeight"]     as? Int    { cfg.graphHeight     = h }
        if let d = config["historyDirectory"] as? String { cfg.historyDirectory = d }
        if let x = config["defaultXMin"]     as? Double { cfg.defaultXMin     = x }
        if let x = config["defaultXMax"]     as? Double { cfg.defaultXMax     = x }
        if let p = config["precision"]       as? Int    { cfg.precision        = p }
        if let e = config["enableHistory"]   as? Bool   { cfg.enableHistory    = e }
        if let k = config["apiKey"]          as? String { cfg.apiKey           = k }
        return cfg
    }

    public static func load(fromFile path: String) throws -> AppConfig {
        guard FileManager.default.fileExists(atPath: path) else { return AppConfig() }
        let yaml = try String(contentsOfFile: path, encoding: .utf8)
        return try load(from: yaml)
    }
}
