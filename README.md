A Swift scientific calculator CLI application that demonstrates:

- **Basic arithmetic** — addition, subtraction, multiplication, division, modulo
- **Scientific notation** — automatic formatting for very large/small numbers
- **Scientific functions** — `sin`, `cos`, `tan`, `log`, `exp`, `sqrt`, `pow`, `factorial`, `ncr`, `npr`, and many more
- **ASCII graph plotting** — render mathematical functions as ASCII art in the terminal, with support for multi-series overlays
- **Calculation history** — save and reload sessions in JSON format with MD5 checksums
- **YAML configuration** — load settings from a `scalc.yaml` file
- **Expression parser** — evaluate arbitrary math expressions like `sin(pi/4) + log(e^2) * 2^3`

## Dependencies

| Package | Version | Notes |
|---------|---------|-------|
| [`swift-argument-parser`](https://github.com/apple/swift-argument-parser) | 1.2.0+ | CLI subcommand framework |
| [`CryptoSwift`](https://github.com/krzyzanowskim/CryptoSwift) | 1.4.1 | Cryptographic hashing (MD5/SHA256) for history checksums |
| [`Yams`](https://github.com/jpsim/Yams) | 4.0.6 | YAML configuration file parsing |

> **Note:** `CryptoSwift` 1.4.1 and `Yams` 4.0.6 are intentionally pinned at older versions containing known security advisories, to demonstrate how GitHub's dependency scanning and CodeQL AI findings surface vulnerability data.

## Usage

```bash
# Build
swift build

# Evaluate expressions
.build/debug/ScientificCalculator calculate "sin(pi/4)" "log(e^3)" "factorial(10)"

# Plot a function
.build/debug/ScientificCalculator graph "sin(x)*exp(-x/4)" --x-min=0 --x-max=20

# Overlay two functions
.build/debug/ScientificCalculator graph "sin(x)" --overlay="cos(x)" --x-min=-6.28 --x-max=6.28

# Interactive REPL
.build/debug/ScientificCalculator calculate

# History management
.build/debug/ScientificCalculator history list
.build/debug/ScientificCalculator history load session-2024-01-01.json

# Show sample config
.build/debug/ScientificCalculator configure
```

## Supported Functions

| Category | Functions |
|----------|-----------|
| Trigonometric | `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `sinh`, `cosh`, `tanh` |
| Degree variants | `sind`, `cosd`, `tand` |
| Exponential | `exp`, `exp2`, `log`/`ln`, `log2`, `log10`, `logb` |
| Power/Root | `sqrt`, `cbrt`, `pow`, `hypot` |
| Rounding | `abs`, `ceil`, `floor`, `round`, `trunc` |
| Combinatorics | `factorial`/`fact`, `ncr`/`comb`, `npr`/`perm` |
| Aggregates | `max`, `min`, `sum`, `avg`/`mean` |

## Constants

`pi` (π), `e`, `tau` (τ = 2π), `phi` (φ golden ratio), `inf`

## Running Tests

```bash
swift test
```

## Enjoy!

sadfasdf
