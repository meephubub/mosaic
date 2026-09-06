import SwiftData
import Foundation

/// Data access for tasks. Repositories isolate SwiftData from services/views.
/// A single long-lived `mainContext` backs all access so fetched models stay
/// valid across the app's lifetime.
@MainActor
struct TaskRepository {
    let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [
                SortDescriptor(\.isCompleted),
                SortDescriptor(\.dueDate),
                SortDescriptor(\.createdAt)
            ]
        )
        return try context.fetch(descriptor)
    }

    func fetchToday() throws -> [TodoItem] {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now
        // In-memory filtering keeps the predicate macro-free and is plenty
        // fast at personal-workspace scale.
        return try fetchAll().filter { item in
            let reference = item.dueDate ?? item.createdAt
            return reference >= start && reference < end
        }
    }

    func insert(_ item: TodoItem) throws {
        context.insert(item)
        try context.save()
    }

    func delete(_ item: TodoItem) throws {
        context.delete(item)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}

/// Data access for notes.
@MainActor
struct NoteRepository {
    let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [NoteModel] {
        let descriptor = FetchDescriptor<NoteModel>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func search(_ query: String) throws -> [NoteModel] {
        guard !query.isEmpty else { return try fetchAll() }
        let all = try fetchAll()
        let lowered = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(lowered) || $0.content.lowercased().contains(lowered)
        }
    }

    func findByID(_ id: UUID) throws -> NoteModel? {
        let descriptor = FetchDescriptor<NoteModel>(predicate: #Predicate<NoteModel> { note in
            note.id == id
        })
        return try context.fetch(descriptor).first
    }

    func insert(_ note: NoteModel) throws {
        context.insert(note)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}

/// Data access for conversations.
@MainActor
struct ConversationRepository {
    let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [ConversationModel] {
        let descriptor = FetchDescriptor<ConversationModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func mostRecent() throws -> ConversationModel? {
        try fetchAll().first
    }

    func insert(_ conversation: ConversationModel) throws {
        context.insert(conversation)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
