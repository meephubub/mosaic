import SwiftUI

/// A single chat bubble styled by role — user filled, assistant airy.
struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .font(message.kind == .error ? DS.Typography.meta : DS.Typography.chatBody)
                .foregroundStyle(textColor)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(bubbleBackground, in: .rect(cornerRadius: DS.Radii.lg))
                .overlay(alignment: message.role == .user ? .bottomTrailing : .bottomLeading) {
                    Circle()
                        .fill(bubbleBackground)
                        .frame(width: 14, height: 14)
                        .mask(alignment: message.role == .user ? .bottomTrailing : .bottomLeading) {
                            Circle().frame(width: 28, height: 28).offset(x: 14, y: 14)
                        }
                }
            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .accessibilityLabel("\(message.role == .user ? "You" : "Mosaic") said: \(message.text)")
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user:
            return DS.Colors.userBubble(scheme: colorScheme)
        case .assistant, .system:
            return Color(nsColor: .textBackgroundColor).opacity(0.9)
        }
    }

    private var textColor: Color {
        switch message.role {
        case .user:
            return DS.Colors.userBubbleText(scheme: colorScheme)
        default:
            return .primary
        }
    }
}

/// Animated dots while the assistant thinks.
struct ThinkingIndicator: View {
    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 5, height: 5)
                    .offset(y: phase == index ? -3 : 0)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.9), in: .rect(cornerRadius: DS.Radii.lg))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                phase = 1
            }
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(500))
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = (phase + 1) % 3
                    }
                }
            }
        }
        .accessibilityLabel("Thinking")
    }
}

/// Shows tool activity inline during agent turns.
struct ToolActivityBubble: View {
    let summary: String

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(summary)
                .font(DS.Typography.meta)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: DS.Radii.sm))
    }
}
