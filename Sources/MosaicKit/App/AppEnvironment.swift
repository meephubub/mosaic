import SwiftUI

/// The composition root. Owns every service instance and hands them out to
/// both the floating assistant and the workspace window so the two interfaces
/// always operate on the exact same state.
@MainActor
@Observable
final class AppEnvironment {
    let services: AppServices
    let floatingAssistant: FloatingAssistantController
    let navigator: WorkspaceNavigator

    private var assistantTask: Task<Void, Never>?

    public init() {
        let persistence = PersistenceController()
        let navigator = WorkspaceNavigator()
        let taskService = TaskService(repository: TaskRepository(container: persistence.container))
        let noteService = NoteService(repository: NoteRepository(container: persistence.container))
        let services = AppServices(
            taskService: taskService,
            noteService: noteService,
            conversationService: ConversationService(
                repository: ConversationRepository(container: persistence.container),
                provider: MockAIProvider(),
                taskService: taskService,
                noteService: noteService,
                navigator: navigator
            ),
            settings: AppSettings()
        )
        self.services = services
        self.navigator = navigator
        self.floatingAssistant = FloatingAssistantController(
            services: services,
            navigator: navigator
        )
    }

    /// Starts global cursor monitoring once the app is running.
    func start() {
        guard assistantTask == nil else { return }
        floatingAssistant.startMonitoring()
        assistantTask = Task { [floatingAssistant] in
            for await state in floatingAssistant.stateStream {
                // Observability hook for future side effects (analytics, etc.).
                _ = state
            }
        }
    }
}

/// The service bundle handed to views, tools, and the agent.
@MainActor
@Observable
final class AppServices {
    let taskService: TaskService
    let noteService: NoteService
    let conversationService: ConversationService
    let settings: AppSettings

    init(
        taskService: TaskService,
        noteService: NoteService,
        conversationService: ConversationService,
        settings: AppSettings
    ) {
        self.taskService = taskService
        self.noteService = noteService
        self.conversationService = conversationService
        self.settings = settings
    }
}

/// Lightweight persisted settings.
@Observable
final class AppSettings {
    @ObservationIgnored @AppStorage("mosaic.assistant.edge") var preferredEdgeRaw: String = "left"
    @ObservationIgnored @AppStorage("mosaic.assistant.enabled") var assistantEnabled: Bool = true

    var preferredEdge: AssistantEdge {
        get { AssistantEdge(rawValue: preferredEdgeRaw) ?? .left }
        set { preferredEdgeRaw = newValue.rawValue }
    }
}
