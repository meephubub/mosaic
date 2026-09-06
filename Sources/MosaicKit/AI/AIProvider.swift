import Foundation

/// The role of a chat message participant.
enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

/// The presentation kind of a chat message.
enum MessageKind: String, Codable, Sendable {
    case text
    case toolActivity
    case error
}

/// One streaming event from an AI provider. Providers are fully replaceable;
/// the UI never knows which one is active.
enum ProviderEvent: Sendable {
    case thinkingStarted
    case thinkingEnded
    case textDelta(String)
    case messageComplete
    case toolCall(ToolCall)
    case toolResult(ToolResult)
    case error(AIError)
    case finished
}

/// Errors surfaced through the provider stream.
struct AIError: Error, Sendable {
    var message: String
}

/// The provider abstraction. A real LLM provider implements this later; the
/// mock ships now so the whole app works without credentials.
protocol AIProvider: Sendable {
    var displayName: String { get }

    /// Streams a response for the given conversation history and context.
    /// The provider may emit tool calls; the agent executes them and calls
    /// this again with the appended tool results.
    func respond(
        history: [ProviderMessage],
        tools: [ToolDefinition],
        context: AssistantContext
    ) -> AsyncThrowingStream<ProviderEvent, Error>
}

/// A provider-agnostic message snapshot.
struct ProviderMessage: Sendable {
    var role: MessageRole
    var text: String
    var kind: MessageKind = .text
}
