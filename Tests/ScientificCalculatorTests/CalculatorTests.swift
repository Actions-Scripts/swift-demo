import XCTest
@testable import ScientificCalculator
import CryptoSwift

final class CalculatorTests: XCTestCase {

    var calc: Calculator!

    override func setUp() {
        super.setUp()
        calc = Calculator()
    }

    // MARK: - Basic arithmetic

    func testAdd() {
        XCTAssertEqual(calc.add(3, 4), 7)
        XCTAssertEqual(calc.add(-1, 1), 0)
    }

    func testSubtract() {
        XCTAssertEqual(calc.subtract(10, 4), 6)
        XCTAssertEqual(calc.subtract(0, 5), -5)
    }

    func testMultiply() {
        XCTAssertEqual(calc.multiply(6, 7), 42)
        XCTAssertEqual(calc.multiply(-3, 4), -12)
    }

    func testDivide() throws {
        XCTAssertEqual(try calc.divide(10, 2), 5)
        XCTAssertEqual(try calc.divide(1, 4), 0.25)
    }

    func testDivideByZeroThrows() {
        XCTAssertThrowsError(try calc.divide(5, 0))
    }

    func testModulo() throws {
        XCTAssertEqual(try calc.modulo(10, 3), 1)
    }

    // MARK: - Expression evaluator

    func testSimpleExpression() throws {
        XCTAssertEqual(try calc.evaluate("2 + 3"), 5)
        XCTAssertEqual(try calc.evaluate("10 - 4"), 6)
        XCTAssertEqual(try calc.evaluate("3 * 4"), 12)
        XCTAssertEqual(try calc.evaluate("10 / 4"), 2.5)
    }

    func testExpressionOperatorPrecedence() throws {
        XCTAssertEqual(try calc.evaluate("2 + 3 * 4"), 14)
        XCTAssertEqual(try calc.evaluate("(2 + 3) * 4"), 20)
    }

    func testExpressionPower() throws {
        XCTAssertEqual(try calc.evaluate("2^10"), 1024)
        XCTAssertEqual(try calc.evaluate("4^0.5"), 2)
    }

    func testUnaryMinus() throws {
        XCTAssertEqual(try calc.evaluate("-5 + 10"), 5)
        XCTAssertEqual(try calc.evaluate("-(3 + 2)"), -5)
    }

    func testConstantPi() throws {
        let result = try calc.evaluate("pi")
        XCTAssertEqual(result, Double.pi, accuracy: 1e-10)
    }

    func testConstantE() throws {
        let result = try calc.evaluate("e")
        XCTAssertEqual(result, M_E, accuracy: 1e-10)
    }

    // MARK: - Scientific functions

    func testSin() throws {
        let result = try calc.evaluate("sin(pi/2)")
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }

    func testCos() throws {
        let result = try calc.evaluate("cos(0)")
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }

    func testTan() throws {
        let result = try calc.evaluate("tan(pi/4)")
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }

    func testLog() throws {
        let result = try calc.evaluate("log(e)")
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }

    func testLog10() throws {
        let result = try calc.evaluate("log10(100)")
        XCTAssertEqual(result, 2.0, accuracy: 1e-10)
    }

    func testLog2() throws {
        let result = try calc.evaluate("log2(8)")
        XCTAssertEqual(result, 3.0, accuracy: 1e-10)
    }

    func testSqrt() throws {
        XCTAssertEqual(try calc.evaluate("sqrt(144)"), 12.0, accuracy: 1e-10)
    }

    func testSqrtNegativeThrows() throws {
        XCTAssertThrowsError(try calc.evaluate("sqrt(-1)"))
    }

    func testExp() throws {
        let result = try calc.evaluate("exp(1)")
        XCTAssertEqual(result, M_E, accuracy: 1e-10)
    }

    func testFactorial() throws {
        XCTAssertEqual(try calc.evaluate("factorial(5)"), 120)
        XCTAssertEqual(try calc.evaluate("factorial(0)"), 1)
    }

    func testCombinations() throws {
        // C(5,2) = 10
        XCTAssertEqual(try calc.evaluate("ncr(5,2)"), 10)
    }

    func testPermutations() throws {
        // P(5,2) = 20
        XCTAssertEqual(try calc.evaluate("npr(5,2)"), 20)
    }

    func testAtan2() throws {
        let result = try calc.evaluate("atan2(1,1)")
        XCTAssertEqual(result, Double.pi / 4, accuracy: 1e-10)
    }

    func testHypot() throws {
        let result = try calc.evaluate("hypot(3,4)")
        XCTAssertEqual(result, 5.0, accuracy: 1e-10)
    }

    func testComplexExpression() throws {
        // Euler identity: e^(i*pi) = -1  — real part approximation via Taylor expansion
        let result = try calc.evaluate("sin(pi/2)^2 + cos(pi/2)^2")
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }

    // MARK: - History tracking

    func testHistoryRecorded() throws {
        _ = try calc.evaluate("2 + 2")
        _ = try calc.evaluate("sin(pi)")
        XCTAssertEqual(calc.history.count, 2)
        XCTAssertEqual(calc.history[0].expression, "2 + 2")
        XCTAssertEqual(calc.history[0].result, 4)
    }

    // MARK: - Formatted result

    func testFormattedResultScientificNotation() throws {
        _ = try calc.evaluate("1e15")
        let record = calc.history.last!
        XCTAssertTrue(record.formattedResult.contains("e"), "Should use scientific notation for large numbers")
    }

    func testFormattedResultSmallScientific() throws {
        _ = try calc.evaluate("1e-8")
        let record = calc.history.last!
        XCTAssertTrue(record.formattedResult.contains("e"), "Should use scientific notation for tiny numbers")
    }
}

// MARK: - Scientific operations tests

final class ScientificOperationsTests: XCTestCase {

    func testFactorialValues() {
        XCTAssertEqual(ScientificOperations.factorial(0), 1)
        XCTAssertEqual(ScientificOperations.factorial(1), 1)
        XCTAssertEqual(ScientificOperations.factorial(5), 120)
        XCTAssertEqual(ScientificOperations.factorial(10), 3_628_800)
    }

    func testUnknownFunctionThrows() throws {
        XCTAssertThrowsError(
            try ScientificOperations.callFunction(name: "unknown", args: [1.0])
        )
    }

    func testMaxMinSum() throws {
        let max = try ScientificOperations.callFunction(name: "max", args: [3, 1, 4, 1, 5, 9])
        let min = try ScientificOperations.callFunction(name: "min", args: [3, 1, 4, 1, 5, 9])
        let sum = try ScientificOperations.callFunction(name: "sum", args: [1, 2, 3, 4, 5])
        let avg = try ScientificOperations.callFunction(name: "avg", args: [1, 2, 3, 4, 5])
        XCTAssertEqual(max, 9)
        XCTAssertEqual(min, 1)
        XCTAssertEqual(sum, 15)
        XCTAssertEqual(avg, 3)
    }
}

// MARK: - Graph plotter tests

final class GraphPlotterTests: XCTestCase {

    func testPlotProducesOutput() {
        let series = GraphPlotter.PlotSeries(name: "sin(x)", symbol: "*") { sin($0) }
        let output = GraphPlotter.plot(
            series: [series],
            config: GraphPlotter.PlotConfig(width: 40, height: 12, xMin: -Double.pi, xMax: Double.pi)
        )
        XCTAssertFalse(output.isEmpty)
        XCTAssertTrue(output.contains("*"), "Plot should contain data points")
    }

    func testPlotEmptySeriesReturnsMessage() {
        let output = GraphPlotter.plot(series: [])
        XCTAssertEqual(output, "(nothing to plot)")
    }

    func testMultiSeriesPlot() {
        let s1 = GraphPlotter.PlotSeries(name: "sin(x)", symbol: "*") { sin($0) }
        let s2 = GraphPlotter.PlotSeries(name: "cos(x)", symbol: "#") { cos($0) }
        let output = GraphPlotter.plot(
            series: [s1, s2],
            config: GraphPlotter.PlotConfig(width: 40, height: 12)
        )
        XCTAssertTrue(output.contains("Legend:"))
        XCTAssertTrue(output.contains("sin(x)"))
        XCTAssertTrue(output.contains("cos(x)"))
    }
}

// MARK: - CryptoSwift integration tests

final class CryptoSwiftIntegrationTests: XCTestCase {

    func testMD5NotEmpty() {
        let hash = HistoryManager.md5("hello world")
        XCTAssertFalse(hash.isEmpty)
        XCTAssertEqual(hash.count, 32, "MD5 produces 32 hex characters")
    }

    func testSHA256NotEmpty() {
        let hash = HistoryManager.sha256("hello world")
        XCTAssertFalse(hash.isEmpty)
        XCTAssertEqual(hash.count, 64, "SHA256 produces 64 hex characters")
    }

    func testMD5Deterministic() {
        let a = HistoryManager.md5("test")
        let b = HistoryManager.md5("test")
        XCTAssertEqual(a, b)
    }
}

// MARK: - Config loader tests

final class ConfigLoaderTests: XCTestCase {

    func testDefaultConfig() {
        let cfg = AppConfig()
        XCTAssertEqual(cfg.graphWidth, 80)
        XCTAssertEqual(cfg.graphHeight, 24)
        XCTAssertEqual(cfg.defaultXMin, -10)
        XCTAssertEqual(cfg.defaultXMax, 10)
        XCTAssertTrue(cfg.enableHistory)
    }

    func testLoadFromYaml() throws {
        let yaml = """
        graphWidth: 120
        graphHeight: 40
        defaultXMin: -5.0
        defaultXMax: 5.0
        precision: 10
        enableHistory: false
        """
        let cfg = try AppConfig.load(from: yaml)
        XCTAssertEqual(cfg.graphWidth, 120)
        XCTAssertEqual(cfg.graphHeight, 40)
        XCTAssertEqual(cfg.defaultXMin, -5.0)
        XCTAssertEqual(cfg.defaultXMax, 5.0)
        XCTAssertEqual(cfg.precision, 10)
        XCTAssertFalse(cfg.enableHistory)
    }

    func testLoadFromInvalidYamlReturnsDefault() throws {
        let cfg = try AppConfig.load(from: "not: valid: yaml: : :")
        // Should fall back to defaults rather than crash
        XCTAssertEqual(cfg.graphWidth, 80)
    }
}
