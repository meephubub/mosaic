import Foundation

/// A single slash command. Registration-based — no view hardcoding.
struct SlashCommand: Identifiable, Hashable {
    var name: String            // e.g. "task"
    var description: String
    var placeholder: String

    var id: String { name }
    var invocation: String { "/\(name)" }
}

/// Outcome of running a slash command.
enum SlashCommandOutcome {
    /// The command completed synchronously via services.
    case handledLocally(message: String?)
    /// The remaining text should be sent through the AI pipeline.
    case forwardToAgent(text: String)
}

/// Executes a resolved command with its argument text.
@MainActor
protocol SlashCommandHandler: Sendable {
    func execute(argument: String) async -> SlashCommandOutcome
}

/// Registry of available slash commands, plus fuzzy-ish prefix filtering.
@MainActor
final class SlashCommandRegistry {
    private(set) var commands: [SlashCommand] = []
    private var handlers: [String: any SlashCommandHandler] = [:]

    func register(_ command: SlashCommand, handler: any SlashCommandHandler) {
        commands.append(command)
        handlers[command.name] = handler
    }

    func command(named name: String) -> SlashCommand? {
        commands.first { $0.name == name }
    }

    func suggestions(for query: String) -> [SlashCommand] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("/") else { return [] }
        let partial = String(trimmed.dropFirst()).lowercased()
        if partial.isEmpty {
            return commands.sorted { $0.name < $1.name }
        }
        return commands
            .filter { $0.name.hasPrefix(partial) || $0.name.lowercased().contains(partial) }
            .sorted { $0.name < $1.name }
    }

    func handler(for command: SlashCommand) -> (any SlashCommandHandler)? {
        handlers[command.name]
    }

    /// Parses an input string into (command, argument) if it begins with a
    /// known command.
    func parse(_ input: String) -> (command: SlashCommand, argument: String)? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("/") else { return nil }
        let parts = trimmed.dropFirst().split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        guard let namePart = parts.first else { return nil }
        let lowered = namePart.lowercased()
        guard let command = commands.first(where: { $0.name == lowered }) else { return nil }
        let argument = parts.count > 1 ? String(parts[1]) : ""
        return (command, argument)
    }
}
