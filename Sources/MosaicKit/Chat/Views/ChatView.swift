import SwiftUI

/// The compact floating chat: bot identity, message bubbles, slash menu, input.
struct ChatView: View {
    @Bindable var controller: ChatController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        ForEach(controller.visibleMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .transition(reduceMotion
                                    ? .opacity
                                    : .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                        }
                        if controller.isThinking {
                            ThinkingIndicator()
                                .id("thinking")
                        }
                        ForEach(Array(controller.pendingToolSummaries.enumerated()), id: \.offset) { _, summary in
                            ToolActivityBubble(summary: summary)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                }
                .onChange(of: controller.visibleMessages.count) {
                    if let last = controller.visibleMessages.last {
                        withAnimation(reduceMotion ? nil : DS.Animations.smooth) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
        .onAppear { inputFocused = true }
        .onExitCommand { controller.dismissSuggestions() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: DS.Spacing.sm) {
            BotView(mood: controller.isThinking ? .thinking : .idle, size: 26)
            VStack(alignment: .leading, spacing: 0) {
                Text("Mosaic")
                    .font(DS.Typography.chatBodyMedium)
                Text(controller.isThinking ? "thinking…" : "your workspace companion")
                    .font(DS.Typography.meta)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Menu {
                Button("New conversation") { controller.newConversation() }
                if controller.closesFloatingPanel {
                    Button("Open full workspace") {
                        NotificationCenter.default.post(name: .openWorkspaceWindow, object: nil)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            if controller.closesFloatingPanel {
                Button {
                    NotificationCenter.default.post(name: .closeFloatingAssistant, object: nil)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.dsPress)
                .help("Close")
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: Input

    private var inputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button {
                // Future: attach files, quick-create note/task.
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.dsPress)
            .help("Quick actions (soon)")

            TextField("Ask anything…", text: $controller.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(DS.Typography.chatBody)
                .lineLimit(1...4)
                .focused($inputFocused)
                .onSubmit(handleSubmit)

            Button(action: handleSubmit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(Color.accentColor))
            }
            .buttonStyle(.dsPress)
            .disabled(controller.draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.leading, DS.Spacing.md)
        .padding(.trailing, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
        .overlay(alignment: .bottom) {
            if controller.hasSuggestions {
                SlashCommandMenu(
                    suggestions: controller.suggestions,
                    selectedIndex: controller.selectedSuggestionIndex,
                    onSelect: { command in
                        controller.draft = command.invocation + " "
                    }
                )
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DS.Animations.smooth, value: controller.hasSuggestions)
    }

    private func handleSubmit() {
        // Enter confirms a slash command; otherwise sends.
        if controller.hasSuggestions, !controller.draft.trimmingCharacters(in: .whitespaces).isEmpty {
            let firstWord = controller.draft.split(separator: " ").first.map(String.init) ?? ""
            let exact = controller.suggestions.first { $0.invocation == firstWord }
            if let exact {
                controller.draft = exact.invocation + " "
                return
            }
        }
        controller.send()
        inputFocused = true
    }
}
