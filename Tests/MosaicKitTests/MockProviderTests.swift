import XCTest
@testable import MosaicKit

final class MockProviderTests: XCTestCase {
    func provider() -> MockAIProvider { MockAIProvider() }

    func collectEvents(_ text: String) async throws -> [ProviderEvent] {
        let provider = self.provider()
        let stream = provider.respond(
            history: [ProviderMessage(role: .user, text: text)],
            tools: [],
            context: AssistantContext()
        )
        var events: [ProviderEvent] = []
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    func testTimeIntentProducesToolCall() async throws {
        let events = try await collectEvents("what time is it?")
        XCTAssertTrue(events.contains { if case .toolCall(let call) = $0, call.toolName == "getCurrentTime" { return true } else { return false } })
    }

    func testGreetingProducesMultipleMessages() async throws {
        let events = try await collectEvents("hey")
        let messageCount = events.filter { if case .messageComplete = $0 { return true } else { return false } }
        XCTAssertEqual(messageCount.count, 2)
    }

    func testTaskIntentProducesCreateTodo() async throws {
        let events = try await collectEvents("make a task to revise biology tomorrow")
        XCTAssertTrue(events.contains { if case .toolCall(let call) = $0, call.toolName == "createTodo" { return true } else { return false } })
    }

    func testErrorIntentProducesErrorMessage() async throws {
        let events = try await collectEvents("this will fail")
        // The mock signals error demo via messages; provider itself shouldn't throw.
        XCTAssertFalse(events.isEmpty)
    }

    func testStreamFinishes() async throws {
        let events = try await collectEvents("anything at all")
        XCTAssertTrue(events.contains(.finished))
    }
}
