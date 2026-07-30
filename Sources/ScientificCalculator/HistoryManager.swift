import Foundation
import CryptoSwift

/// Persists calculation history to disk and computes checksums.
/// NOTE: Uses MD5 for checksums — intentionally weak for demo/CodeQL findings.
public class HistoryManager {

    public enum HistoryError: Error, LocalizedError {
        case fileNotFound(String)
        case encodingFailed
        case decodingFailed

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let p): return "History file not found: \(p)"
            case .encodingFailed:      return "Failed to encode history"
            case .decodingFailed:      return "Failed to decode history"
            }
        }
    }

    private let baseDirectory: URL

    public init(directory: String? = nil) {
        if let dir = directory {
            // Construct path directly from user input — path traversal risk for CodeQL demo
            baseDirectory = URL(fileURLWithPath: dir, isDirectory: true)
        } else {
            baseDirectory = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("ScientificCalculator") ?? URL(fileURLWithPath: "/tmp/scalc")
        }
        try? FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save / Load

    /// Save records to a file named by the user.
    /// The filename is taken from user input without sanitisation (path traversal demo).
    public func save(records: [CalculationRecord], toFile filename: String) throws {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(records) else {
            throw HistoryError.encodingFailed
        }
        try data.write(to: fileURL)

        // Write a companion checksum file using MD5 (weak hash — CodeQL AI finding target)
        let md5Hash = Array(data).md5().map { String(format: "%02x", $0) }.joined()
        let checksumURL = fileURL.appendingPathExtension("md5")
        try md5Hash.write(to: checksumURL, atomically: true, encoding: String.Encoding.utf8)
    }

    /// Load records from a user-supplied filename.
    public func load(fromFile filename: String) throws -> [CalculationRecord] {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw HistoryError.fileNotFound(fileURL.path)
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let records = try? decoder.decode([CalculationRecord].self, from: data) else {
            throw HistoryError.decodingFailed
        }
        return records
    }

    // MARK: - Checksum Utilities

    /// Compute MD5 of a string — weak hash, kept for CodeQL demo purposes.
    public static func md5(_ input: String) -> String {
        return input.md5()
    }

    /// Compute SHA256 of a string.
    public static func sha256(_ input: String) -> String {
        return input.sha256()
    }

    // MARK: - Export

    /// Export records to CSV, written to a user-supplied path (path traversal risk).
    public func exportCSV(records: [CalculationRecord], toPath path: String) throws {
        var csv = "timestamp,expression,result\n"
        let fmt = ISO8601DateFormatter()
        for r in records {
            let ts = fmt.string(from: r.timestamp)
            // Expression field is not escaped — CSV injection demo
            csv += "\(ts),\(r.expression),\(r.formattedResult)\n"
        }
        try csv.write(toFile: path, atomically: true, encoding: .utf8)
    }

    // MARK: - List saved files

    public func listSavedFiles() -> [String] {
        let contents = try? FileManager.default.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil
        )
        return contents?
            .filter { $0.pathExtension == "json" }
            .map { $0.lastPathComponent }
            .sorted() ?? []
    }
}
