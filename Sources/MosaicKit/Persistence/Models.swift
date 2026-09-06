import SwiftData
import Foundation

/// A task. Named `TodoItem` to avoid colliding with Swift concurrency's `Task`.
@Model
final class TodoItem {
    var id: UUID
    var title: String
    var notesText: String
    var dueDate: Date?
    var isCompleted: Bool
    var priorityRaw: String
    var tagsRaw: [String]
    var createdAt: Date
    var completedAt: Date?

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        tags: [String] = [],
        createdAt: Date = .now,
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.notesText = notes
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.tagsRaw = tags
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var tags: [String] {
        get { tagsRaw }
        set { tagsRaw = newValue }
    }
}

/// Priority levels for tasks.
enum TaskPriority: String, CaseIterable, Codable, Comparable {
    case low, medium, high

    var label: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var sortRank: Int {
        switch self {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortRank < rhs.sortRank
    }
}

/// A note. Text-based for Phase 1, with metadata reserved for a future block model.
@Model
final class NoteModel {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String, content: String = "", createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
}

/// A chat conversation.
@Model
final class ConversationModel {
    var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessageModel.conversation)
    var messages: [ChatMessageModel] = []

    init(title: String = "New chat", createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
    }
}

/// A single chat message. `roleRaw`/`kindRaw` store the enums; computed
/// properties expose the typed values.
@Model
final class ChatMessageModel {
    var id: UUID
    var text: String
    var roleRaw: String
    var kindRaw: String
    var sentAt: Date
    var conversation: ConversationModel?

    init(
        text: String,
        role: MessageRole,
        kind: MessageKind = .text,
        sentAt: Date = .now
    ) {
        self.id = UUID()
        self.text = text
        self.roleRaw = role.rawValue
        self.kindRaw = kind.rawValue
        self.sentAt = sentAt
    }

    var role: MessageRole {
        get { MessageRole(rawValue: roleRaw) ?? .assistant }
        set { roleRaw = newValue.rawValue }
    }

    var kind: MessageKind {
        get { MessageKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }
}
