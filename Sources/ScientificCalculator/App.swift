import ArgumentParser
import Foundation

@main
struct ScientificCalculatorApp: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scalc",
        abstract: "A scientific calculator with graphing capabilities",
        version: "1.0.0",
        subcommands: [
            Calculate.self,
            Graph.self,
            History.self,
            Configure.self,
        ],
        defaultSubcommand: Calculate.self
    )
}
