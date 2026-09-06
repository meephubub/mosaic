import SwiftData
import Foundation

/// Owns the shared `ModelContainer`. One store backs the whole app so the
/// assistant and workspace never diverge. Tests can use an in-memory store.
@MainActor
final class PersistenceController {
    let container: ModelContainer

    init(inMemory: Bool = false) {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(
                for: TodoItem.self, NoteModel.self, ConversationModel.self, ChatMessageModel.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

/// Convenience for building preview/test environments.
@MainActor
enum InMemoryPersistence {
    static func make() -> PersistenceController {
        PersistenceController(inMemory: true)
    }
}
