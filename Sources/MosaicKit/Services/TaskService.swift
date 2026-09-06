import Foundation
import SwiftData
import Observation

/// Logging helper so services can report errors without UIKit-style alerts.
enum MosaicLog {
    static func info(_ message: String) { print("[Mosaic] \(message)") }
    static func error(_ message: String) { print("[Mosaic] ERROR: \(message)") }
}

/// The single writer for task state. Both the manual Tasks UI and the AI's
/// `createTodo` tool go through this, guaranteeing one source of truth.
@MainActor
@Observable
final class TaskService {
    private let repository: TaskRepository

    /// All tasks, refreshed after mutations so SwiftUI updates.
    private(set) var tasks: [TodoItem] = []

    init(repository: TaskRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            tasks = try repository.fetchAll()
        } catch {
            MosaicLog.error("TaskService.reload failed: \(error)")
        }
    }

    @discardableResult
    func create(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        tags: [String] = []
    ) -> TodoItem {
        let item = TodoItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            tags: tags
        )
        do {
            try repository.insert(item)
        } catch {
            MosaicLog.error("TaskService.create failed: \(error)")
        }
        reload()
        return item
    }

    func toggleComplete(_ item: TodoItem) {
        item.isCompleted.toggle()
        item.completedAt = item.isCompleted ? .now : nil
        save()
    }

    func update(_ item: TodoItem, title: String? = nil, dueDate: Date? = nil, priority: TaskPriority? = nil) {
        if let title { item.title = title }
        if let dueDate { item.dueDate = dueDate }
        if let priority { item.priority = priority }
        save()
    }

    func delete(_ item: TodoItem) {
        do {
            try repository.delete(item)
        } catch {
            MosaicLog.error("TaskService.delete failed: \(error)")
        }
        reload()
    }

    private func save() {
        do {
            try repository.save()
        } catch {
            MosaicLog.error("TaskService.save failed: \(error)")
        }
    }
}
