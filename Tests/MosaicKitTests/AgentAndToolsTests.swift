import XCTest
import SwiftData
@testable import MosaicKit

/// A scripted provider used to drive the agent loop deterministically.
private struct ScriptedProvider: AIProvider {
    let displayName = "Scripted"
    var script: @Sendable ([ProviderMessage], [ToolDefinition]) -> [ProviderEvent]

    func respond(
        history: [ProviderMessage],
        tools: [ToolDefinition],
        context: AssistantContext
    ) -> AsyncThrowingStream<ProviderEvent, Error> {
        let events = script(history, tools)
        return AsyncThrowingStream { continuation in
            continuation.yield(.thinkingStarted)
            for event in events { continuation.yield(event) }
            continuation.yield(.finished)
            continuation.finish()
        }
    }
}

@MainActor
final class AgentAndToolsTests: XCTestCase {
    var persistence: PersistenceController!
    var taskService: TaskService!
    var noteService: NoteService!
    var navigator: WorkspaceNavigator!
    var registry: ToolRegistry!

    override func setUp() async throws {
        persistence = PersistenceController(inMemory: true)
        taskService = TaskService(repository: TaskRepository(container: persistence.container))
        noteService = NoteService(repository: NoteRepository(container: persistence.container))
        navigator = WorkspaceNavigator()
        registry = ToolRegistry(tools: [
            GetCurrentDateTool(),
            GetCurrentTimeTool(),
            CreateTodoTool(taskService: taskService),
            ListTodosTool(taskService: taskService),
            CreateNoteTool(noteService: noteService),
            SearchNotesTool(noteService: noteService),
            OpenPageTool(navigator: navigator)
        ])
    }

    // MARK: Tools

    func testCreateTodoTool() async {
        let call = ToolCall(id: "1", toolName: "createTodo", arguments: ["title": "Revise biology", "dueDate": "tomorrow"])
        let result = await registry.execute(call)
        XCTAssertTrue(result.success)
        XCTAssertEqual(taskService.tasks.count, 1)
        XCTAssertNotNil(taskService.tasks.first?.dueDate)
    }

    func testCreateTodoToolMissingTitleFails() async {
        let call = ToolCall(id: "2", toolName: "createTodo", arguments: [:])
        let result = await registry.execute(call)
        XCTAssertFalse(result.success)
    }

    func testListTodosTool() async {
        taskService.create(title: "Task A")
        let call = ToolCall(id: "3", toolName: "listTodos", arguments: [:])
        let result = await registry.execute(call)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.summary.contains("Task A"))
    }

    func testCreateAndSearchNotesTool() async {
        noteService.create(title: "Cell Structure", content: "mitochondria produce ATP")
        let search = ToolCall(id: "4", toolName: "searchNotes", arguments: ["query": "mitochondria"])
        let result = await registry.execute(search)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.summary.contains("Cell Structure"))
    }

    func testOpenPageTool() async {
        let call = ToolCall(id: "5", toolName: "openPage", arguments: ["section": "tasks"])
        let result = await registry.execute(call)
        XCTAssertTrue(result.success)
        XCTAssertEqual(navigator.selectedSection, .tasks)
    }

    func testUnknownToolFailsGracefully() async {
        let call = ToolCall(id: "6", toolName: "nonexistent", arguments: [:])
        let result = await registry.execute(call)
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.summary.contains("Unknown tool"))
    }

    func testRegistryDefinitionsExposed() {
        let names = registry.definitions.map(\.name)
        XCTAssertTrue(names.contains("getCurrentDate"))
        XCTAssertTrue(names.contains("createNote"))
        XCTAssertEqual(names.count, 7)
    }

    // MARK: Agent loop

    func testAgentRunsToolAndContinues() async throws {
        // Turn 1: provider asks for a tool. Turn 2: provider sees the result and replies.
        let provider = ScriptedProvider { history, _ -> [ProviderEvent] in
            let sawToolResult = history.contains { $0.role == .system && $0.text.contains("createTodo") }
            if !sawToolResult {
                return [
                    .textDelta("on it"),
                    .messageComplete,
                    .toolCall(ToolCall(id: "c1", toolName: "createTodo", arguments: ["title": "Agent task"]))
                ]
            }
            return [
                .textDelta("done"),
                .messageComplete
            ]
        }

        let events = try await Agent().runTurn(
            history: [ProviderMessage(role: .user, text: "add a task")],
            registry: registry,
            provider: provider,
            context: AssistantContext()
        )

        XCTAssertTrue(events.contains { if case .toolFinished = $0 { return true } else { return false } })
        XCTAssertEqual(taskService.tasks.count, 1)
        XCTAssertEqual(taskService.tasks.first?.title, "Agent task")
        XCTAssertTrue(events.contains { event in
            if case .finished = event { return true }
            return false
        })
    }

    func testAgentWithoutToolCallFinishesQuickly() async throws {
        let provider = ScriptedProvider { _, _ in
            [.textDelta("hello there"), .messageComplete]
        }
        let events = try await Agent().runTurn(
            history: [ProviderMessage(role: .user, text: "hi")],
            registry: registry,
            provider: provider,
            context: AssistantContext()
        )
        XCTAssertFalse(events.contains { if case .toolStarted = $0 { return true } else { return false } })
        XCTAssertTrue(events.contains { if case .messageChunk(let text) = $0, text == "hello there" { return true } else { return false } })
    }

    // MARK: Conversation persistence

    func testConversationPersistsMessages() async throws {
        let repository = ConversationRepository(container: persistence.container)
        let conversation = try repository.mostRecent() ?? ConversationModel()
        if conversation.messages.isEmpty {
            try repository.insert(conversation)
        }
        let message = ChatMessageModel(text: "hello", role: .user)
        message.conversation = conversation
        conversation.messages.append(message)
        try repository.save()
        let reloaded = try XCTUnwrap(try repository.mostRecent())
        XCTAssertEqual(reloaded.messages.count, 1)
        XCTAssertEqual(reloaded.messages.first?.text, "hello")
    }
}
