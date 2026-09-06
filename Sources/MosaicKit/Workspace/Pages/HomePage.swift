import SwiftUI

/// Home — a calm dashboard of today's tasks and recent notes.
struct HomePage: View {
    @Environment(\.appServices) private var services
    @Environment(WorkspaceNavigator.self) private var navigator

    private var todayTasks: [TodoItem] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        return services.taskService.tasks.filter { item in
            !item.isCompleted && (item.dueDate.map { $0 < start.addingTimeInterval(86400) } ?? false)
        }
    }

    private var recentNotes: [NoteModel] {
        Array(services.noteService.notes.prefix(4))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                header
                HSplitView {
                    tasksCard
                        .frame(maxWidth: .infinity, alignment: .leading)
                    notesCard
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 240)
            }
            .padding(DS.Spacing.xl)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(pageTitle)
                .font(DS.Typography.pageTitle)
            Text(subtitle)
                .font(DS.Typography.meta)
                .foregroundStyle(.secondary)
        }
    }

    private var pageTitle: String {
        "Good \(dayPhase)"
    }

    private var dayPhase: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "morning"
        case 12..<18: "afternoon"
        default: "evening"
        }
    }

    private var subtitle: String {
        let count = todayTasks.count
        if count == 0 { return "You're all clear today." }
        return "\(count) task\(count == 1 ? "" : "s") due today"
    }

    private var tasksCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DSSectionHeader(title: "Today")
            if todayTasks.isEmpty {
                Text("Nothing due — enjoy it.")
                    .font(DS.Typography.chatBody)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayTasks.prefix(5), id: \.id) { item in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.tertiary)
                        Text(item.title)
                            .font(DS.Typography.chatBody)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .dsCard()
        .contentShape(.rect)
        .onTapGesture { navigator.open(.tasks) }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DSSectionHeader(title: "Recent notes")
            if recentNotes.isEmpty {
                Text("No notes yet.")
                    .font(DS.Typography.chatBody)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentNotes, id: \.id) { note in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(DS.Typography.cardTitle)
                        Text(note.content.isEmpty ? "Empty note" : String(note.content.prefix(60)))
                            .font(DS.Typography.meta)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .dsCard()
        .contentShape(.rect)
        .onTapGesture { navigator.open(.notes) }
    }
}
