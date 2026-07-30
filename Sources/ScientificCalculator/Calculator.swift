import Foundation

/// Core calculator providing basic arithmetic and expression evaluation.
public class Calculator {

    public enum CalculatorError: Error, LocalizedError {
        case divisionByZero
        case invalidExpression(String)
        case overflow
        case underflow
        case domainError(String)

        public var errorDescription: String? {
            switch self {
            case .divisionByZero:        return "Division by zero"
            case .invalidExpression(let s): return "Invalid expression: \(s)"
            case .overflow:              return "Result overflow"
            case .underflow:             return "Result underflow"
            case .domainError(let s):    return "Domain error: \(s)"
            }
        }
    }

    // History of evaluated expressions — stored in memory and optionally flushed to disk.
    public private(set) var history: [CalculationRecord] = []

    public init() {}

    // MARK: - Arithmetic

    public func add(_ a: Double, _ b: Double) -> Double { a + b }
    public func subtract(_ a: Double, _ b: Double) -> Double { a - b }
    public func multiply(_ a: Double, _ b: Double) -> Double { a * b }

    public func divide(_ a: Double, _ b: Double) throws -> Double {
        guard b != 0 else { throw CalculatorError.divisionByZero }
        return a / b
    }

    public func modulo(_ a: Double, _ b: Double) throws -> Double {
        guard b != 0 else { throw CalculatorError.divisionByZero }
        return a.truncatingRemainder(dividingBy: b)
    }

    // MARK: - Expression Evaluator (simple recursive-descent parser)

    /// Evaluate a mathematical expression string, e.g. "3 + sin(pi/2) * 2^3"
    public func evaluate(_ expression: String) throws -> Double {
        let tokens = try tokenise(expression)
        var index = 0
        let result = try parseExpression(tokens: tokens, index: &index)
        guard index == tokens.count else {
            throw CalculatorError.invalidExpression("Unexpected token at position \(index)")
        }
        let record = CalculationRecord(expression: expression, result: result)
        history.append(record)
        return result
    }

    // MARK: - Token types

    private enum Token {
        case number(Double)
        case identifier(String)
        case op(Character)
        case leftParen
        case rightParen
        case comma
    }

    private func tokenise(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = input.replacingOccurrences(of: " ", with: "")
        var i = chars.startIndex

        while i < chars.endIndex {
            let ch = chars[i]
            if ch.isNumber || ch == "." {
                var numStr = String(ch)
                var j = chars.index(after: i)
                while j < chars.endIndex && (chars[j].isNumber || chars[j] == "." || chars[j] == "e" || chars[j] == "E" || ((chars[j] == "+" || chars[j] == "-") && j > chars.startIndex && (chars[chars.index(before: j)] == "e" || chars[chars.index(before: j)] == "E"))) {
                    numStr.append(chars[j])
                    j = chars.index(after: j)
                }
                guard let n = Double(numStr) else {
                    throw CalculatorError.invalidExpression("Bad number: \(numStr)")
                }
                tokens.append(.number(n))
                i = j
            } else if ch.isLetter || ch == "_" {
                var id = String(ch)
                var j = chars.index(after: i)
                while j < chars.endIndex && (chars[j].isLetter || chars[j].isNumber || chars[j] == "_") {
                    id.append(chars[j])
                    j = chars.index(after: j)
                }
                tokens.append(.identifier(id))
                i = j
            } else if ch == "(" {
                tokens.append(.leftParen)
                i = chars.index(after: i)
            } else if ch == ")" {
                tokens.append(.rightParen)
                i = chars.index(after: i)
            } else if ch == "," {
                tokens.append(.comma)
                i = chars.index(after: i)
            } else if "+-*/^%".contains(ch) {
                tokens.append(.op(ch))
                i = chars.index(after: i)
            } else {
                throw CalculatorError.invalidExpression("Unknown character: \(ch)")
            }
        }
        return tokens
    }

    // MARK: - Recursive-descent parser

    private func parseExpression(tokens: [Token], index: inout Int) throws -> Double {
        var left = try parseTerm(tokens: tokens, index: &index)
        while index < tokens.count, case .op(let op) = tokens[index], op == "+" || op == "-" {
            index += 1
            let right = try parseTerm(tokens: tokens, index: &index)
            left = op == "+" ? left + right : left - right
        }
        return left
    }

    private func parseTerm(tokens: [Token], index: inout Int) throws -> Double {
        var left = try parsePower(tokens: tokens, index: &index)
        while index < tokens.count, case .op(let op) = tokens[index], op == "*" || op == "/" || op == "%" {
            index += 1
            let right = try parsePower(tokens: tokens, index: &index)
            switch op {
            case "*": left = left * right
            case "/":
                guard right != 0 else { throw CalculatorError.divisionByZero }
                left = left / right
            case "%":
                guard right != 0 else { throw CalculatorError.divisionByZero }
                left = left.truncatingRemainder(dividingBy: right)
            default: break
            }
        }
        return left
    }

    private func parsePower(tokens: [Token], index: inout Int) throws -> Double {
        let base = try parseUnary(tokens: tokens, index: &index)
        if index < tokens.count, case .op(let op) = tokens[index], op == "^" {
            index += 1
            let exp = try parsePower(tokens: tokens, index: &index)
            return pow(base, exp)
        }
        return base
    }

    private func parseUnary(tokens: [Token], index: inout Int) throws -> Double {
        if index < tokens.count, case .op(let op) = tokens[index], op == "-" {
            index += 1
            return -(try parseAtom(tokens: tokens, index: &index))
        }
        if index < tokens.count, case .op(let op) = tokens[index], op == "+" {
            index += 1
        }
        return try parseAtom(tokens: tokens, index: &index)
    }

    private func parseAtom(tokens: [Token], index: inout Int) throws -> Double {
        guard index < tokens.count else {
            throw CalculatorError.invalidExpression("Unexpected end of expression")
        }
        switch tokens[index] {
        case .number(let n):
            index += 1
            return n
        case .identifier(let name):
            index += 1
            // Named constants
            if let constant = ScientificConstants.value(for: name) {
                return constant
            }
            // Functions — expect (args...)
            guard index < tokens.count, case .leftParen = tokens[index] else {
                throw CalculatorError.invalidExpression("Unknown identifier '\(name)'")
            }
            index += 1 // consume '('
            var args: [Double] = []
            if index < tokens.count, case .rightParen = tokens[index] {
                // no args
            } else {
                args.append(try parseExpression(tokens: tokens, index: &index))
                while index < tokens.count, case .comma = tokens[index] {
                    index += 1
                    args.append(try parseExpression(tokens: tokens, index: &index))
                }
            }
            guard index < tokens.count, case .rightParen = tokens[index] else {
                throw CalculatorError.invalidExpression("Expected ')' after function arguments")
            }
            index += 1 // consume ')'
            return try ScientificOperations.callFunction(name: name, args: args)
        case .leftParen:
            index += 1
            let val = try parseExpression(tokens: tokens, index: &index)
            guard index < tokens.count, case .rightParen = tokens[index] else {
                throw CalculatorError.invalidExpression("Expected closing parenthesis")
            }
            index += 1
            return val
        default:
            throw CalculatorError.invalidExpression("Unexpected token")
        }
    }
}

// MARK: - Calculation Record

public struct CalculationRecord: Codable {
    public let expression: String
    public let result: Double
    public let timestamp: Date

    public init(expression: String, result: Double) {
        self.expression = expression
        self.result = result
        self.timestamp = Date()
    }

    public var formattedResult: String {
        if result.isNaN { return "NaN" }
        if result.isInfinite { return result > 0 ? "∞" : "-∞" }
        // Use scientific notation for very large or very small numbers
        if abs(result) >= 1e10 || (abs(result) < 1e-4 && result != 0) {
            return String(format: "%.6e", result)
        }
        return String(format: "%g", result)
    }
}
