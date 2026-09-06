import Foundation
import Observation
import SwiftData

/// Orchestrates a chat conversation: builds context, invokes the agent, and
/// persists every message. Sits between the view models and the agent.
@MainActor
@Observable
final class ConversationService {
    private let repository: ConversationRepository
    private let registry: ToolRegistry
    private let agent = Agent()

    private(set) var lastError: String?

    init(
        repository: ConversationRepository,
        provider: any AIProvider,
        taskService: TaskService,
        noteService: NoteService,
        navigator: WorkspaceNavigator
    ) {
        self.repository = repository
        self.registry = ToolRegistry(tools: [
            GetCurrentDateTool(),
            GetCurrentTimeTool(),
            CreateTodoTool(taskService: taskService),
            ListTodosTool(taskService: taskService),
            CreateNoteTool(noteService: noteService),
            SearchNotesTool(noteService: noteService),
            OpenPageTool(navigator: navigator)
        ])
        self.provider = provider
    }

    var provider: any AIProvider

    // MARK: - Persistence

    @discardableResult
    func loadOrCreateConversation() -> ConversationModel {
        if let recent = try? repository.mostRecent() {
            return recent
        }
        let conversation = ConversationModel()
        try? repository.insert(conversation)
        return conversation
    }

    func persist(conversation: ConversationModel) {
        do {
            try repository.save()
        } catch {
            MosaicLog.error("ConversationService.persist failed: \(error)")
        }
    }

    @discardableResult
    func append(
        text: String,
        role: MessageRole,
        kind: MessageKind = .text,
        to conversation: ConversationModel
    ) -> ChatMessageModel {
        let message = ChatMessageModel(text: text, role: role, kind: kind)
        message.conversation = conversation
        conversation.messages.append(message)
        persist(conversation: conversation)
        return message
    }

    func history(in conversation: ConversationModel) -> [ProviderMessage] {
        conversation.messages
            .sorted { $0.sentAt < $1.sentAt }
            .map { ProviderMessage(role: $0.role, text: $0.text, kind: $0.kind) }
    }

    // MARK: - Turn execution

    /// Runs one agent turn for the user's message: persists the user message,
    /// streams assistant messages through `onEvent`, persists results.
    func runTurn(
        userText: String,
        in conversation: ConversationModel,
        context: AssistantContext,
        onEvent: @escaping @MainActor (AgentEvent) -> Void
    ) async {
        lastError = nil
        append(text: userText, role: .user, to: conversation)

        let history = history(in: conversation)
        var currentAssistantText = ""

        do {
            let events = try await agent.runTurn(
                history: history,
                registry: registry,
                provider: provider,
                context: context
            )

            for event in events {
                switch event {
                case .thinkingStarted:
                    onEvent(.thinkingStarted)
                case .thinkingEnded:
                    onEvent(.thinkingEnded)
                case .messageChunk(let chunk):
                    // Multi-message replies arrive as separate completed chunks;
                    // the view model sequences them visually.
                    currentAssistantText += chunk
                    onEvent(.messageChunk(chunk))
                case .messageCompleted:
                    onEvent(.messageCompleted)
                case .toolStarted(let call):
                    onEvent(.toolStarted(call))
                case .toolFinished(let result):
                    onEvent(.toolFinished(result))
                case .error(let aiError):
                    lastError = aiError.message
                    onEvent(.error(aiError))
                case .finished:
                    if !currentAssistantText.isEmpty {
                        append(text: currentAssistantText, role: .assistant, to: conversation)
                        currentAssistantText = ""
                    }
                    onEvent(.finished)
                }
            }
        } catch {
            lastError = error.localizedDescription
            let message = "hm, something went wrong — \(error.localizedDescription)"
            append(text: message, role: .assistant, kind: .error, to: conversation)
            onEvent(.error(AIError(message: message)))
            onEvent(.finished)
        }
    }
}
