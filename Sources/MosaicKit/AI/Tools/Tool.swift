import Foundation

/// Static description of a tool, exposed to providers in a model-agnostic way.
struct ToolDefinition: Sendable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var description: String
    /// JSON Schema-ish parameter description for future LLM providers.
    var parameters: [ToolParameter]
}

struct ToolParameter: Sendable, Hashable {
    var name: String
    var type: String
    var description: String
    var isRequired: Bool
}

/// A provider's request to invoke a tool.
struct ToolCall: Sendable, Identifiable {
    var id: String
    var toolName: String
    var arguments: [String: String]
}

/// The outcome of a tool invocation.
struct ToolResult: Sendable {
    var toolCallID: String
    var toolName: String
    var success: Bool
    var summary: String
    var payload: [String: String]
}

/// A stateful, async tool. Tools are registered once and resolved by name.
/// All Phase 1 tools mutate shared services, never view state.
protocol Tool: Sendable {
    var definition: ToolDefinition { get }
    @MainActor
    func execute(_ call: ToolCall) async throws -> ToolResult
}

extension Tool {
    func result(
        for call: ToolCall,
        success: Bool,
        summary: String,
        payload: [String: String] = [:]
    ) -> ToolResult {
        ToolResult(
            toolCallID: call.id,
            toolName: call.toolName,
            success: success,
            summary: summary,
            payload: payload
        )
    }
}
