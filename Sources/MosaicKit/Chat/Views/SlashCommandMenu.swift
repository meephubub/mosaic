import SwiftUI

/// The animated command palette that appears inside the chat when the user
/// types "/". Keyboard-first: arrows navigate, Enter selects, Esc dismisses.
struct SlashCommandMenu: View {
    let suggestions: [SlashCommand]
    var selectedIndex: Int
    var onSelect: (SlashCommand) -> Void

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, command in
                row(command, index: index)
            }
        }
        .padding(DS.Spacing.xs)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: DS.Radii.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radii.md)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private func row(_ command: SlashCommand, index: Int) -> some View {
        let isSelected = index == selectedIndex
        return Button {
            onSelect(command)
        } label: {
            HStack {
                Text(command.invocation)
                    .font(DS.Typography.chatBodyMedium)
                    .monospaced()
                Text(command.description)
                    .font(DS.Typography.meta)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) : .clear,
                in: .rect(cornerRadius: DS.Radii.sm)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { selectedIndex = index }
        }
    }
}
