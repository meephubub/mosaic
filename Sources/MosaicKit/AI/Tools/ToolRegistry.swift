import Foundation

/// Resolves tools by name. Adding future tools means registering one more
/// instance here — the agent and provider never change.
@MainActor
final class ToolRegistry {
    private var tools: [String: any Tool] = [:]

    init(tools: [any Tool]) {
        for tool in tools {
            self.tools[tool.definition.name] = tool
        }
    }

    var definitions: [ToolDefinition] {
        tools.values.map(\.definition).sorted { $0.name < $1.name }
    }

    func tool(named name: String) -> (any Tool)? {
        tools[name]
    }

    @discardableResult
    func register(_ tool: any Tool) -> Bool {
        guard tools[tool.definition.name] == nil else { return false }
        tools[tool.definition.name] = tool
        return true
    }

    func execute(_ call: ToolCall) async -> ToolResult {
        guard let tool = tools[call.toolName] else {
            return ToolResult(
                toolCallID: call.id,
                toolName: call.toolName,
                success: false,
                summary: "Unknown tool: \(call.toolName)",
                payload: [:]
            )
        }
        do {
            return try await tool.execute(call)
        } catch {
            return ToolResult(
                toolCallID: call.id,
                toolName: call.toolName,
                success: false,
                summary: error.localizedDescription,
                payload: [:]
            )
        }
    }
}
