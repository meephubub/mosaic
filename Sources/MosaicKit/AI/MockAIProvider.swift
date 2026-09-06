import Foundation

/// A deterministic provider that needs no credentials. Demonstrates thinking
/// state, tool calls, multi-message replies, and error handling. Replaceable
/// with a real LLM provider — nothing downstream knows this is a mock.
struct MockAIProvider: AIProvider {
    let displayName = "Mosaic Mock"

    func respond(
        history: [ProviderMessage],
        tools: [ToolDefinition],
        context: AssistantContext
    ) -> AsyncThrowingStream<ProviderEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                // After tool results are fed back, summarise them instead of
                // re-deriving the original intent (prevents a tool-call loop).
                if let summary = Self.toolResultSummary(from: history) {
                    await emit(.thinkingStarted, to: continuation)
                    try? await Task.sleep(for: .milliseconds(250))
                    await emit(.thinkingEnded, to: continuation)
                    for chunk in summary {
                        await emit(.textDelta(chunk), to: continuation)
                        await emit(.messageComplete, to: continuation)
                    }
                    await emit(.finished, to: continuation)
                    continuation.finish()
                    return
                }

                let lastUserText = history.last(where: { $0.role == .user })?.text ?? ""

                await emit(.thinkingStarted, to: continuation)
                try? await Task.sleep(for: .milliseconds(450))
                await emit(.thinkingEnded, to: continuation)

                let intent = classify(lastUserText, context: context)

                for (index, chunk) in intent.messages.enumerated() {
                    if index > 0 {
                        try? await Task.sleep(for: .milliseconds(280))
                    }
                    await emit(.textDelta(chunk), to: continuation)
                    await emit(.messageComplete, to: continuation)
                }

                for call in intent.toolCalls {
                    await emit(.toolCall(call), to: continuation)
                }

                await emit(.finished, to: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Intent classification

    private struct MockIntent {
        var messages: [String]
        var toolCalls: [ToolCall]
    }

    /// Extracts a conversational summary from tool-result messages the agent
    /// appended to the history.
    private static func toolResultSummary(from history: [ProviderMessage]) -> [String]? {
        let toolMessages = history.filter { $0.role == .system && $0.text.hasPrefix("Tool ") }
        guard let last = toolMessages.last else { return nil }
        let name = last.text
            .dropFirst("Tool ".count)
            .prefix { $0 != " " }
        let summary = last.text.drop { $0 != "→" }.dropFirst(1).trimmingCharacters(in: .whitespaces)
        switch name {
        case "getCurrentTime":
            return ["it's \(summary)", "what are you planning?"]
        case "getCurrentDate":
            return ["today is \(summary)"]
        case "createTodo":
            return ["done — \(summary.lowercased())", "want me to add another?"]
        case "listTodos":
            if summary == "No tasks yet." {
                return ["you've got nothing on the list", "want to add something?"]
            }
            return ["here's what you've got:", summary]
        case "createNote":
            return ["saved — \(summary.lowercased())"]
        case "searchNotes":
            if summary.hasPrefix("No notes") {
                return ["couldn't find anything for that"]
            }
            return ["found some:", summary]
        case "openPage":
            return [summary]
        default:
            return [summary]
        }
    }

    private func classify(_ text: String, context: AssistantContext) -> MockIntent {
        let lowered = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if lowered.isEmpty {
            return MockIntent(messages: ["say something and I'll do it"], toolCalls: [])
        }

        if lowered.contains("error") || lowered.contains("fail") {
            return MockIntent(messages: ["hm, that broke — try again?"], toolCalls: [])
        }

        if isGreeting(lowered) {
            return MockIntent(
                messages: ["hey", "what are we doing today?"],
                toolCalls: []
            )
        }

        if containsAny(lowered, ["time"]) {
            let call = ToolCall(id: UUID().uuidString, toolName: "getCurrentTime", arguments: [:])
            return MockIntent(messages: ["one sec"], toolCalls: [call])
        }

        if containsAny(lowered, ["what day", "date today", "today's date"]) {
            let call = ToolCall(id: UUID().uuidString, toolName: "getCurrentDate", arguments: [:])
            return MockIntent(messages: ["checking"], toolCalls: [call])
        }

        if containsAny(lowered, ["my tasks", "what tasks", "list tasks", "todo"]) {
            let call = ToolCall(id: UUID().uuidString, toolName: "listTodos", arguments: [:])
            return MockIntent(messages: ["let me look"], toolCalls: [call])
        }

        if containsAny(lowered, ["create a task", "add a task", "new task", "make a task", "remind me to"]) {
            let title = extractTaskTitle(from: text)
            var arguments = ["title": title]
            if let range = lowered.range(of: "tomorrow") {
                _ = range
                arguments["dueDate"] = "tomorrow"
            }
            let call = ToolCall(id: UUID().uuidString, toolName: "createTodo", arguments: arguments)
            return MockIntent(messages: ["on it"], toolCalls: [call])
        }

        if containsAny(lowered, ["note about", "make a note", "new note", "create a note"]) {
            let title = extractNoteTitle(from: text)
            let call = ToolCall(
                id: UUID().uuidString,
                toolName: "createNote",
                arguments: ["title": title]
            )
            return MockIntent(messages: ["got it"], toolCalls: [call])
        }

        if containsAny(lowered, ["find my notes", "show my", "search my", "show me my", "chemistry notes", "biology notes"]) {
            let query = extractSearchQuery(from: text)
            let call = ToolCall(id: UUID().uuidString, toolName: "searchNotes", arguments: ["query": query])
            return MockIntent(messages: ["searching"], toolCalls: [call])
        }

        if containsAny(lowered, ["open ", "go to ", "show "]) {
            for section in WorkspaceSection.allCases {
                if lowered.contains(section.title.lowercased()) {
                    let call = ToolCall(
                        id: UUID().uuidString,
                        toolName: "openPage",
                        arguments: ["section": section.rawValue]
                    )
                    return MockIntent(messages: ["opening \(section.title.lowercased())"], toolCalls: [call])
                }
            }
        }

        return MockIntent(
            messages: defaultResponse(for: text, context: context),
            toolCalls: []
        )
    }

    private func isGreeting(_ lowered: String) -> Bool {
        ["hi", "hey", "hello", "yo", "sup"].contains { lowered == $0 || lowered.hasPrefix($0 + " ") }
        || lowered.hasPrefix("hey ")
        || lowered.hasPrefix("hi ")
        || lowered.hasPrefix("hello ")
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private func extractTaskTitle(from text: String) -> String {
        var title = text
        for prefix in ["create a task", "add a task", "new task", "make a task", "remind me to"] {
            if let range = title.lowercased().range(of: prefix) {
                title = String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: " .!?"))
        return title.isEmpty ? text : title
    }

    private func extractNoteTitle(from text: String) -> String {
        var title = text
        if let range = title.lowercased().range(of: "note about") {
            title = String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        } else if let range = title.lowercased().range(of: "note") {
            title = String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: " .!?"))
        return title.isEmpty ? "New note" : title
    }

    private func extractSearchQuery(from text: String) -> String {
        var query = text
        for prefix in ["find my notes on", "show me my", "show my", "search my", "find my"] {
            if let range = query.lowercased().range(of: prefix) {
                query = String(query[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        query = query.trimmingCharacters(in: CharacterSet(charactersIn: " .!?"))
        return query.isEmpty ? text : query
    }

    private func defaultResponse(for text: String, context: AssistantContext) -> [String] {
        let openCount = context.openTaskTitles.count
        var lines: [String] = []
        lines.append("not sure I follow — \"\(text.trimmedPrefix(60))\"")
        if openCount > 0 {
            lines.append("you've got \(openCount) open task\(openCount == 1 ? "" : "s") if that helps")
        }
        lines.append("try /help to see what I can do")
        return lines
    }
}

private extension String {
    func trimmedPrefix(_ limit: Int) -> String {
        if count <= limit { return self }
        return String(prefix(limit)) + "…"
    }
}

/// Streams an event onto the continuation from any context.
private func emit(_ event: ProviderEvent, to continuation: AsyncThrowingStream<ProviderEvent, Error>.Continuation) async {
    continuation.yield(event)
}
