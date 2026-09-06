import Foundation

/// High-level events the agent emits to the conversation layer.
enum AgentEvent: Sendable {
    case thinkingStarted
    case thinkingEnded
    case messageChunk(String)
    case messageCompleted
    case toolStarted(ToolCall)
    case toolFinished(ToolResult)
    case error(AIError)
    case finished
}

/// Runs the provider→tool loop: stream a response, execute requested tools,
/// feed results back, and continue until the provider finishes. The agent is
/// provider-agnostic and grows without rewrites as tools are added.
struct Agent: Sendable {
    var maxToolIterations: Int = 5

    /// Runs one full conversational turn. Returns the events in order.
    @MainActor
    func runTurn(
        history: [ProviderMessage],
        registry: ToolRegistry,
        provider: any AIProvider,
        context: AssistantContext
    ) async throws -> [AgentEvent] {
        var events: [AgentEvent] = []
        var workingHistory = history
        var toolResultsThisTurn: [ToolResult] = []

        await MainActor.run { events.append(.thinkingStarted) }

        for _ in 0..<maxToolIterations {
            let stream = provider.respond(
                history: workingHistory,
                tools: registry.definitions,
                context: context
            )

            var sawToolCall = false
            var turnText = ""

            for try await event in stream {
                switch event {
                case .thinkingStarted:
                    continue
                case .thinkingEnded:
                    continue
                case .textDelta(let delta):
                    turnText += delta
                    events.append(.messageChunk(delta))
                case .messageComplete:
                    events.append(.messageCompleted)
                case .toolCall(let call):
                    sawToolCall = true
                    events.append(.toolStarted(call))
                    let result = await registry.execute(call)
                    toolResultsThisTurn.append(result)
                    events.append(.toolFinished(result))
                case .toolResult:
                    continue
                case .error(let aiError):
                    events.append(.error(aiError))
                case .finished:
                    continue
                }
            }

            if !sawToolCall {
                break
            }

            // Feed tool results back so the provider can summarise them.
            workingHistory.append(ProviderMessage(role: .assistant, text: turnText))
            for result in toolResultsThisTurn {
                workingHistory.append(
                    ProviderMessage(role: .system, text: "Tool \(result.toolName) → \(result.summary)")
                )
            }
            toolResultsThisTurn.removeAll()
        }

        events.append(.finished)
        return events
    }
}
