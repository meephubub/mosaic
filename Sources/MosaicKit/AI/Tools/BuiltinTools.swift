import Foundation

// MARK: - Date/time tools

struct GetCurrentDateTool: Tool {
    let definition = ToolDefinition(
        name: "getCurrentDate",
        description: "Returns today's date in the user's calendar and locale.",
        parameters: []
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let now = Date.now
        let timeZone = TimeZone.current.identifier
        let formatted = formatter.string(from: now)
        let iso = ISO8601DateFormatter().string(from: now)
        return result(
            for: call,
            success: true,
            summary: formatted,
            payload: ["iso": iso, "timeZone": timeZone]
        )
    }
}

struct GetCurrentTimeTool: Tool {
    let definition = ToolDefinition(
        name: "getCurrentTime",
        description: "Returns the current local time.",
        parameters: []
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let now = Date.now
        let formatted = formatter.string(from: now)
        let iso = ISO8601DateFormatter().string(from: now)
        return result(
            for: call,
            success: true,
            summary: formatted,
            payload: ["iso": iso]
        )
    }
}

// MARK: - Task tools

struct CreateTodoTool: Tool {
    let taskService: TaskService

    let definition = ToolDefinition(
        name: "createTodo",
        description: "Creates a task with a title, optional due date, priority, and tags.",
        parameters: [
            ToolParameter(name: "title", type: "string", description: "The task title", isRequired: true),
            ToolParameter(name: "dueDate", type: "string", description: "Due date description, e.g. 'tomorrow'", isRequired: false),
            ToolParameter(name: "priority", type: "string", description: "low, medium, or high", isRequired: false)
        ]
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        guard let title = call.arguments["title"], !title.isEmpty else {
            return result(for: call, success: false, summary: "Missing title argument.")
        }
        let priority = TaskPriority(rawValue: call.arguments["priority"] ?? "") ?? .medium
        let dueDate = RelativeDateParser.parse(call.arguments["dueDate"])
        let item = taskService.create(title: title, dueDate: dueDate, priority: priority)
        var payload = ["id": item.id.uuidString]
        if let dueDate {
            payload["dueDate"] = dueDate.formatted(date: .abbreviated, time: .omitted)
        }
        return result(for: call, success: true, summary: "Created task '\(title)'", payload: payload)
    }
}

struct ListTodosTool: Tool {
    let taskService: TaskService

    let definition = ToolDefinition(
        name: "listTodos",
        description: "Lists the user's tasks, most urgent first.",
        parameters: []
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        let items = taskService.tasks
        guard !items.isEmpty else {
            return result(for: call, success: true, summary: "No tasks yet.", payload: [:])
        }
        let lines = items.prefix(10).enumerated().map { index, item in
            var line = "\(index + 1). \(item.title)"
            if item.isCompleted { line += " (done)" }
            if let due = item.dueDate {
                line += " — due \(due.formatted(date: .abbreviated, time: .omitted))"
            }
            return line
        }
        return result(
            for: call,
            success: true,
            summary: lines.joined(separator: "\n"),
            payload: ["count": String(items.count)]
        )
    }
}

// MARK: - Note tools

struct CreateNoteTool: Tool {
    let noteService: NoteService

    let definition = ToolDefinition(
        name: "createNote",
        description: "Creates a note with a title and optional content.",
        parameters: [
            ToolParameter(name: "title", type: "string", description: "The note title", isRequired: true),
            ToolParameter(name: "content", type: "string", description: "The note body", isRequired: false)
        ]
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        guard let title = call.arguments["title"], !title.isEmpty else {
            return result(for: call, success: false, summary: "Missing title argument.")
        }
        let content = call.arguments["content"] ?? ""
        let note = noteService.create(title: title, content: content)
        return result(
            for: call,
            success: true,
            summary: "Created note '\(title)'",
            payload: ["id": note.id.uuidString]
        )
    }
}

struct SearchNotesTool: Tool {
    let noteService: NoteService

    let definition = ToolDefinition(
        name: "searchNotes",
        description: "Searches the user's notes by title and content.",
        parameters: [
            ToolParameter(name: "query", type: "string", description: "The search text", isRequired: true)
        ]
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        guard let query = call.arguments["query"], !query.isEmpty else {
            return result(for: call, success: false, summary: "Missing query argument.")
        }
        let matches = noteService.search(query)
        guard !matches.isEmpty else {
            return result(for: call, success: true, summary: "No notes matching '\(query)'.", payload: [:])
        }
        let lines = matches.prefix(8).map { note in
            var line = note.title
            if !note.content.isEmpty {
                let preview = String(note.content.prefix(80))
                line += " — \(preview)"
            }
            return line
        }
        return result(
            for: call,
            success: true,
            summary: lines.joined(separator: "\n"),
            payload: ["count": String(matches.count)]
        )
    }
}

// MARK: - Navigation tool

struct OpenPageTool: Tool {
    let navigator: WorkspaceNavigator

    let definition = ToolDefinition(
        name: "openPage",
        description: "Opens a workspace section: home, notes, tasks, calendar, revision, or ai.",
        parameters: [
            ToolParameter(name: "section", type: "string", description: "The section to open", isRequired: true)
        ]
    )

    func execute(_ call: ToolCall) async throws -> ToolResult {
        guard let raw = call.arguments["section"], let section = WorkspaceSection(rawValue: raw.lowercased()) else {
            return result(for: call, success: false, summary: "Unknown section.")
        }
        navigator.open(section)
        return result(for: call, success: true, summary: "Opened \(section.title).")
    }
}
