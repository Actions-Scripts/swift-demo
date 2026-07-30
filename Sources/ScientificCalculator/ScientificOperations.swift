import Foundation

/// Scientific constants and functions available in expressions.
public enum ScientificConstants {
    private static let constants: [String: Double] = [
        "pi":   Double.pi,
        "π":    Double.pi,
        "e":    M_E,
        "tau":  2 * Double.pi,
        "τ":    2 * Double.pi,
        "phi":  1.6180339887498948482,  // golden ratio
        "inf":  Double.infinity,
    ]

    public static func value(for name: String) -> Double? {
        constants[name.lowercased()]
    }
}

/// All supported scientific/math functions callable from expressions.
public enum ScientificOperations {

    public static func callFunction(name: String, args: [Double]) throws -> Double {
        switch name.lowercased() {
        // Trigonometric (radians)
        case "sin":    return try unary(args, name) { sin($0) }
        case "cos":    return try unary(args, name) { cos($0) }
        case "tan":    return try unary(args, name) { tan($0) }
        case "asin":   return try unary(args, name) { asin($0) }
        case "acos":   return try unary(args, name) { acos($0) }
        case "atan":   return try unary(args, name) { atan($0) }
        case "atan2":  return try binary(args, name) { atan2($0, $1) }
        case "sinh":   return try unary(args, name) { sinh($0) }
        case "cosh":   return try unary(args, name) { cosh($0) }
        case "tanh":   return try unary(args, name) { tanh($0) }

        // Degree variants
        case "sind":   return try unary(args, name) { sin($0 * .pi / 180) }
        case "cosd":   return try unary(args, name) { cos($0 * .pi / 180) }
        case "tand":   return try unary(args, name) { tan($0 * .pi / 180) }

        // Exponential / logarithmic
        case "exp":    return try unary(args, name) { exp($0) }
        case "exp2":   return try unary(args, name) { exp2($0) }
        case "log", "ln": return try unary(args, name) {
            guard $0 > 0 else { throw Calculator.CalculatorError.domainError("log requires positive argument") }
            return log($0)
        }
        case "log2":   return try unary(args, name) {
            guard $0 > 0 else { throw Calculator.CalculatorError.domainError("log2 requires positive argument") }
            return log2($0)
        }
        case "log10":  return try unary(args, name) {
            guard $0 > 0 else { throw Calculator.CalculatorError.domainError("log10 requires positive argument") }
            return log10($0)
        }
        case "logb":   return try binary(args, name) {
            guard $0 > 0 && $1 > 0 && $1 != 1 else { throw Calculator.CalculatorError.domainError("logb requires base > 0, base ≠ 1, and argument > 0") }
            return log($0) / log($1)
        }

        // Power / root
        case "sqrt":   return try unary(args, name) {
            guard $0 >= 0 else { throw Calculator.CalculatorError.domainError("sqrt requires non-negative argument") }
            return sqrt($0)
        }
        case "cbrt":   return try unary(args, name) { cbrt($0) }
        case "pow":    return try binary(args, name) { pow($0, $1) }
        case "hypot":  return try binary(args, name) { hypot($0, $1) }

        // Rounding
        case "abs":    return try unary(args, name) { abs($0) }
        case "ceil":   return try unary(args, name) { ceil($0) }
        case "floor":  return try unary(args, name) { floor($0) }
        case "round":  return try unary(args, name) { round($0) }
        case "trunc":  return try unary(args, name) { trunc($0) }

        // Combinatorics
        case "factorial", "fact": return try unary(args, name) { n in
            guard n >= 0 && n == trunc(n) else {
                throw Calculator.CalculatorError.domainError("factorial requires non-negative integer")
            }
            return ScientificOperations.factorial(Int(n))
        }
        case "ncr", "comb": return try binary(args, name) { n, r in
            try combinations(n: Int(n), r: Int(r))
        }
        case "npr", "perm": return try binary(args, name) { n, r in
            try permutations(n: Int(n), r: Int(r))
        }

        // Statistics helpers
        case "max":    return args.max() ?? .nan
        case "min":    return args.min() ?? .nan
        case "sum":    return args.reduce(0, +)
        case "avg", "mean": return args.isEmpty ? .nan : args.reduce(0, +) / Double(args.count)

        // Miscellaneous
        case "sign":   return try unary(args, name) { $0 < 0 ? -1 : $0 > 0 ? 1 : 0 }
        case "frac":   return try unary(args, name) { $0 - trunc($0) }

        default:
            throw Calculator.CalculatorError.invalidExpression("Unknown function '\(name)'")
        }
    }

    // MARK: - Helpers

    private static func unary(_ args: [Double], _ name: String, _ f: (Double) throws -> Double) throws -> Double {
        guard args.count == 1 else {
            throw Calculator.CalculatorError.invalidExpression("\(name)() requires exactly 1 argument, got \(args.count)")
        }
        return try f(args[0])
    }

    private static func binary(_ args: [Double], _ name: String, _ f: (Double, Double) throws -> Double) throws -> Double {
        guard args.count == 2 else {
            throw Calculator.CalculatorError.invalidExpression("\(name)() requires exactly 2 arguments, got \(args.count)")
        }
        return try f(args[0], args[1])
    }

    public static func factorial(_ n: Int) -> Double {
        if n <= 1 { return 1 }
        var result: Double = 1
        for i in 2...n { result *= Double(i) }
        return result
    }

    private static func combinations(n: Int, r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else {
            throw Calculator.CalculatorError.domainError("Invalid arguments for C(n,r): n=\(n), r=\(r)")
        }
        return factorial(n) / (factorial(r) * factorial(n - r))
    }

    private static func permutations(n: Int, r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else {
            throw Calculator.CalculatorError.domainError("Invalid arguments for P(n,r): n=\(n), r=\(r)")
        }
        return factorial(n) / factorial(n - r)
    }
}
