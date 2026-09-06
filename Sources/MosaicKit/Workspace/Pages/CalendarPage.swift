import SwiftUI

/// Calendar — Phase 1 shows due tasks on a week strip; EventKit comes later.
struct CalendarPage: View {
    @Environment(\.appServices) private var services

    private var upcomingTasks: [TodoItem] {
        services.taskService.tasks
            .filter { !$0.isCompleted && $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Calendar")
                .font(DS.Typography.pageTitle)

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    DSSectionHeader(title: "Upcoming deadlines")
                    if upcomingTasks.isEmpty {
                        Text("No scheduled tasks yet. Create one with a due date, or ask the assistant.")
                            .font(DS.Typography.chatBody)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(upcomingTasks, id: \.id) { item in
                            HStack {
                                Text(item.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                    .font(DS.Typography.meta)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                Text(item.title)
                                    .font(DS.Typography.chatBody)
                                Spacer()
                            }
                        }
                    }
            }
            .dsCard()

            Text("Month and week views arrive in a later phase.")
                .font(DS.Typography.meta)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
