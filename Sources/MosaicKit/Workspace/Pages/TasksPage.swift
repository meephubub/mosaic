import SwiftUI

/// Tasks — fast manual capture and satisfying completion.
struct TasksPage: View {
    @Environment(\.appServices) private var services
    @State private var newTaskTitle = ""
    @FocusState private var newTaskFocused: Bool

    private var taskService: TaskService { services.taskService }

    var body: some View {
        VStack(spacing: 0) {
            header
            addTaskBar
            Divider().padding(.horizontal, DS.Spacing.lg)
            taskList
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text("Tasks")
                .font(DS.Typography.pageTitle)
            Text("\(taskService.tasks.filter { !$0.isCompleted }.count) open")
                .font(DS.Typography.meta)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.top, DS.Spacing.lg)
        .padding(.bottom, DS.Spacing.md)
    }

    private var addTaskBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.secondary)
            TextField("Add a task…", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(DS.Typography.chatBody)
                .focused($newTaskFocused)
                .onSubmit(addTask)
            if !newTaskTitle.isEmpty {
                Button("Add") { addTask() }
                    .buttonStyle(.dsPress)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(.background.secondary, in: .rect(cornerRadius: DS.Radii.md))
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.bottom, DS.Spacing.md)
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let dueDate = RelativeDateParser.parse(title)
        taskService.create(title: title, dueDate: dueDate)
        newTaskTitle = ""
        newTaskFocused = true
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.xs) {
                let open = taskService.tasks.filter { !$0.isCompleted }
                let done = taskService.tasks.filter { $0.isCompleted }

                ForEach(open, id: \.id) { item in
                    TaskRow(item: item)
                }
                if !done.isEmpty {
                    DSSectionHeader(title: "Completed")
                        .padding(.top, DS.Spacing.sm)
                    ForEach(done, id: \.id) { item in
                        TaskRow(item: item)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.vertical, DS.Spacing.md)
        }
    }
}

// MARK: - Task row

struct TaskRow: View {
    @Environment(\.appServices) private var services
    let item: TodoItem

    @State private var checkScale: CGFloat = 1

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button {
                withAnimation(DS.Animations.spring) {
                    services.taskService.toggleComplete(item)
                }
                checkScale = 1.25
                withAnimation(DS.Animations.spring) {
                    checkScale = 1
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(item.isCompleted ? Color.accentColor : .secondary)
                    .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(DS.Typography.chatBody)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                if let due = item.dueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(DS.Typography.meta)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            priorityBadge
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(.background.secondary, in: .rect(cornerRadius: DS.Radii.md))
        .contentShape(.rect)
        .contextMenu {
            Button("Delete", role: .destructive) {
                services.taskService.delete(item)
            }
        }
        .opacity(item.isCompleted ? 0.65 : 1)
    }

    @ViewBuilder
    private var priorityBadge: some View {
        switch item.priority {
        case .high:
            Label("High", systemImage: "exclamationmark.2")
                .font(DS.Typography.meta)
                .foregroundStyle(.red)
        case .medium:
            EmptyView()
        case .low:
            Text("Low")
                .font(DS.Typography.meta)
                .foregroundStyle(.tertiary)
        }
    }
}
