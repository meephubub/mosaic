import XCTest
import SwiftData
@testable import MosaicKit

@MainActor
final class SlashCommandTests: XCTestCase {
    var services: AppServices!
    var registry: SlashCommandRegistry!
    var navigator: WorkspaceNavigator!

    override func setUp() async throws {
        let persistence = PersistenceController(inMemory: true)
        let navigator = WorkspaceNavigator()
        let taskService = TaskService(repository: TaskRepository(container: persistence.container))
        let noteService = NoteService(repository: NoteRepository(container: persistence.container))
        services = AppServices(
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
        self.navigator = navigator
        registry = SlashCommandInstaller.makeRegistry(services: services, navigator: navigator)
    }

    func testSuggestionsWithSlashOnly() {
        let suggestions = registry.suggestions(for: "/")
        XCTAssertEqual(suggestions.count, 7)
    }

    func testSuggestionsFilterPartial() {
        let suggestions = registry.suggestions(for: "/ta")
        XCTAssertEqual(suggestions.map(\.name), ["task"])
    }

    func testSuggestionsIgnoreNonSlash() {
        XCTAssertTrue(registry.suggestions(for: "hello").isEmpty)
    }

    func testParseKnownCommand() {
        let parsed = registry.parse("/task Revise biology tomorrow")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.command.name, "task")
        XCTAssertEqual(parsed?.argument, "Revise biology tomorrow")
    }

    func testParseUnknownCommandReturnsNil() {
        XCTAssertNil(registry.parse("/unknown hello"))
    }

    func testTaskHandlerCreatesTask() async {
        let handler = TaskCommandHandler(taskService: services.taskService)
        let outcome = await handler.execute(argument: "Revise cell biology tomorrow")
        guard case .handledLocally(let message?) = outcome else {
            return XCTFail("Expected handledLocally message")
        }
        XCTAssertTrue(message.contains("cell biology"))
        XCTAssertEqual(services.taskService.tasks.count, 1)
        XCTAssertEqual(services.taskService.tasks.first?.title, "Revise cell biology tomorrow")
        XCTAssertNotNil(services.taskService.tasks.first?.dueDate)
    }

    func testTaskHandlerEmptyArgumentForwardsToAgent() async {
        let handler = TaskCommandHandler(taskService: services.taskService)
        let outcome = await handler.execute(argument: "  ")
        guard case .forwardToAgent = outcome else {
            return XCTFail("Expected forwardToAgent")
        }
    }

    func testNoteHandlerCreatesNote() async {
        let handler = NoteCommandHandler(noteService: services.noteService)
        let outcome = await handler.execute(argument: "Photosynthesis")
        guard case .handledLocally = outcome else {
            return XCTFail("Expected handledLocally")
        }
        XCTAssertEqual(services.noteService.notes.first?.title, "Photosynthesis")
    }

    func testSearchHandlerFindsNotes() async {
        services.noteService.create(title: "Chemistry — bonding", content: "ionic vs covalent")
        let handler = SearchCommandHandler(noteService: services.noteService)
        let outcome = await handler.execute(argument: "chemistry")
        guard case .handledLocally(let message?) = outcome else {
            return XCTFail("Expected handledLocally message")
        }
        XCTAssertTrue(message.contains("Chemistry — bonding"))
    }

    func testHelpHandlerListsCommands() async {
        let handler = HelpCommandHandler(registry: registry)
        let outcome = await handler.execute(argument: "")
        guard case .handledLocally(let message?) = outcome else {
            return XCTFail("Expected handledLocally message")
        }
        XCTAssertTrue(message.contains("/task"))
        XCTAssertTrue(message.contains("/note"))
        XCTAssertTrue(message.contains("/revise"))
    }
}
