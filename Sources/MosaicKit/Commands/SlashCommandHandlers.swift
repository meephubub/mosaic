import Foundation

/// /task — create a task immediately.
struct TaskCommandHandler: SlashCommandHandler {
    let taskService: TaskService

    func execute(argument: String) async -> SlashCommandOutcome {
        let title = argument.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            return .forwardToAgent(text: "make a task")
        }
        let dueDate = RelativeDateParser.parse(title)
        let item = taskService.create(title: title, dueDate: dueDate)
        let when = dueDate.map { " for \($0.formatted(date: .abbreviated, time: .omitted))" } ?? ""
        return .handledLocally(message: "task '\(item.title)'\(when) — done")
    }
}

/// /note — create a note immediately.
struct NoteCommandHandler: SlashCommandHandler {
    let noteService: NoteService

    func execute(argument: String) async -> SlashCommandOutcome {
        let title = argument.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            return .forwardToAgent(text: "make a note")
        }
        let note = noteService.create(title: title)
        return .handledLocally(message: "note '\(note.title)' created")
    }
}

/// /calendar — forward to the agent with calendar framing.
struct CalendarCommandHandler: SlashCommandHandler {
    func execute(argument: String) async -> SlashCommandOutcome {
        .forwardToAgent(text: argument.isEmpty ? "what's on my calendar?" : argument)
    }
}

/// /search — search notes and hand results to the agent for summarising.
struct SearchCommandHandler: SlashCommandHandler {
    let noteService: NoteService

    func execute(argument: String) async -> SlashCommandOutcome {
        let query = argument.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            return .forwardToAgent(text: "search my notes")
        }
        let results = noteService.search(query)
        if results.isEmpty {
            return .handledLocally(message: "no notes matching '\(query)'")
        }
        let list = results.prefix(5).map(\.title).joined(separator: ", ")
        return .handledLocally(message: "found: \(list)")
    }
}

/// /open — jump the workspace to a section.
struct OpenCommandHandler: SlashCommandHandler {
    let navigator: WorkspaceNavigator

    func execute(argument: String) async -> SlashCommandOutcome {
        let lowered = argument.lowercased().trimmingCharacters(in: .whitespaces)
        guard let section = WorkspaceSection.allCases.first(where: { lowered.hasPrefix($0.rawValue) })
        else {
            return .forwardToAgent(text: "open \(argument)")
        }
        navigator.open(section)
        return .handledLocally(message: "opened \(section.title)")
    }
}

/// /revise — placeholder routed to the agent.
struct ReviseCommandHandler: SlashCommandHandler {
    func execute(argument: String) async -> SlashCommandOutcome {
        .forwardToAgent(text: "help me revise \(argument)".trimmingCharacters(in: .whitespaces))
    }
}

/// /help — lists available commands.
struct HelpCommandHandler: SlashCommandHandler {
    let registry: SlashCommandRegistry

    func execute(argument: String) async -> SlashCommandOutcome {
        let list = registry.commands
            .sorted { $0.name < $1.name }
            .map { "/\($0.name) — \($0.description)" }
            .joined(separator: "\n")
        return .handledLocally(message: "here's what I can do:\n\(list)")
    }
}
