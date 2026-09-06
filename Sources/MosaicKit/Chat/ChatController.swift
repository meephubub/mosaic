import SwiftUI
import SwiftData
import Observation

/// Drives a chat surface (floating panel or workspace AI page): owns the
/// visible messages, thinking state, slash command suggestions, and agent runs.
@MainActor
@Observable
final class ChatController {
    // MARK: Dependencies

    private let conversationService: ConversationService
    private let slashRegistry: SlashCommandRegistry
    private let contextProvider: @MainActor () -> AssistantContext

    // MARK: State

    private(set) var conversation: ConversationModel
    private(set) var visibleMessages: [ChatMessage] = []
    private(set) var isThinking = false
    private(set) var pendingToolSummaries: [String] = []
    private(set) var selectedSuggestionIndex = 0
    var draft: String = ""
    private(set) var errorMessage: String?

    /// Whether this surface may close the floating panel (chat in the panel,
    /// not the workspace AI page).
    var closesFloatingPanel = false

    private var sequencerTask: Task<Void, Never>?
    private var turnTask: Task<Void, Never>?
    private var pendingChunks: [String] = []

    // MARK: Init

    init(
        conversationService: ConversationService,
        slashRegistry: SlashCommandRegistry,
        conversation: ConversationModel,
        contextProvider: @escaping @MainActor () -> AssistantContext
    ) {
        self.conversationService = conversationService
        self.slashRegistry = slashRegistry
        self.conversation = conversation
        self.contextProvider = contextProvider
        loadVisibleMessages()
    }

    /// Builds a controller wired to shared services (app runtime).
    static func fromServices(_ services: AppServices, navigator: WorkspaceNavigator?) -> ChatController {
        let conversation = services.conversationService.loadOrCreateConversation()
        return ChatController(
            conversationService: services.conversationService,
            slashRegistry: SlashCommandInstaller.makeRegistry(services: services, navigator: navigator ?? WorkspaceNavigator()),
            conversation: conversation,
            contextProvider: {
                AssistantContext(
                    currentSection: navigator?.selectedSection ?? .home,
                    openTaskTitles: services.taskService.tasks.filter { !$0.isCompleted }.map(\.title),
                    now: .now
                )
            }
        )
    }

    // MARK: Derived

    var suggestions: [SlashCommand] {
        guard draft.hasPrefix("/") else { return [] }
        return slashRegistry.suggestions(for: draft)
    }

    var hasSuggestions: Bool { !suggestions.isEmpty }

    // MARK: Actions

    func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        draft = ""

        if let parsed = slashRegistry.parse(text) {
            runSlashCommand(parsed.command, argument: parsed.argument, echo: text)
        } else {
            runAgentTurn(text: text, echoUser: true)
        }
    }

    private func runSlashCommand(_ command: SlashCommand, argument: String, echo: String) {
        appendVisible(ChatMessage(text: echo, role: .user))
        _ = conversationService.append(text: echo, role: .user, to: conversation)
        guard let handler = slashRegistry.handler(for: command) else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let outcome = await handler.execute(argument: argument)
            switch outcome {
            case .handledLocally(let message):
                if let message {
                    await sequenceAssistantMessages([message])
                }
            case .forwardToAgent(let text):
                runAgentTurn(text: text, echoUser: false)
            }
        }
    }

    private func runAgentTurn(text: String, echoUser: Bool) {
        if echoUser {
            appendVisible(ChatMessage(text: text, role: .user))
        }
        isThinking = true
        pendingToolSummaries = []
        turnTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await conversationService.runTurn(
                userText: text,
                in: conversation,
                context: contextProvider()
            ) { [weak self] event in
                self?.handleAgentEvent(event)
            }
            self.isThinking = false
        }
    }

    private func handleAgentEvent(_ event: AgentEvent) {
        switch event {
        case .thinkingStarted:
            isThinking = true
        case .thinkingEnded:
            break
        case .messageChunk(let chunk):
            pendingChunks.append(chunk)
        case .messageCompleted:
            finalizeQueuedMessage()
        case .toolStarted(let call):
            pendingToolSummaries.append("Running \(call.toolName)…")
        case .toolFinished(let result):
            if let last = pendingToolSummaries.indices.last {
                pendingToolSummaries[last] = result.summary
            }
        case .error(let aiError):
            errorMessage = aiError.message
            appendVisible(ChatMessage(text: aiError.message, role: .assistant, kind: .error))
        case .finished:
            break
        }
    }

    // MARK: Multi-message sequencing

    /// Moves queued chunks into the visible list as separate bubbles with
    /// natural timing (immediate under Reduce Motion).
    private func finalizeQueuedMessage() {
        guard !pendingChunks.isEmpty else { return }
        let chunks = pendingChunks
        pendingChunks.removeAll()

        sequencerTask?.cancel()
        sequencerTask = Task { @MainActor [weak self] in
            for (index, chunk) in chunks.enumerated() {
                if index > 0, !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(320))
                }
                if Task.isCancelled { break }
                self?.appendVisible(ChatMessage(text: chunk, role: .assistant))
            }
        }
    }

    private func sequenceAssistantMessages(_ messages: [String]) async {
        for (index, message) in messages.enumerated() {
            if index > 0, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(320))
            }
            appendVisible(ChatMessage(text: message, role: .assistant))
            _ = conversationService.append(text: message, role: .assistant, to: conversation)
        }
    }

    private func appendVisible(_ message: ChatMessage) {
        visibleMessages.append(message)
    }

    // MARK: Slash menu keyboard navigation

    func moveSelectionDown() {
        guard hasSuggestions else { return }
        selectedSuggestionIndex = min(selectedSuggestionIndex + 1, suggestions.count - 1)
    }

    func moveSelectionUp() {
        guard hasSuggestions else { return }
        selectedSuggestionIndex = max(selectedSuggestionIndex - 1, 0)
    }

    func acceptSelectedSuggestion() {
        guard hasSuggestions else { return }
        let command = suggestions[selectedSuggestionIndex]
        draft = command.invocation + " "
    }

    func dismissSuggestions() {
        if draft.hasPrefix("/") {
            draft = ""
        }
    }

    // MARK: Conversation management

    func newConversation() {
        conversation = conversationService.loadOrCreateConversation()
        loadVisibleMessages()
    }

    private func loadVisibleMessages() {
        visibleMessages = conversation.messages
            .sorted { $0.sentAt < $1.sentAt }
            .map(ChatMessage.init(model:))
    }
}

/// A lightweight value type mirroring a persisted message for the UI.
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var text: String
    var role: MessageRole
    var kind: MessageKind
    var sentAt: Date

    init(id: UUID = UUID(), text: String, role: MessageRole, kind: MessageKind = .text, sentAt: Date = .now) {
        self.id = id
        self.text = text
        self.role = role
        self.kind = kind
        self.sentAt = sentAt
    }

    init(model: ChatMessageModel) {
        self.init(id: model.id, text: model.text, role: model.role, kind: model.kind, sentAt: model.sentAt)
    }
}
