import SwiftUI

// MARK: - Card

/// A calm elevated surface used across the workspace.
struct DSCard: ViewModifier {
    var padding: CGFloat = DS.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.background.secondary, in: .rect(cornerRadius: DS.Radii.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radii.lg)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
    }
}

extension View {
    func dsCard(padding: CGFloat = DS.Spacing.md) -> some View {
        modifier(DSCard(padding: padding))
    }
}

// MARK: - Press-scale button style

/// Buttons subtly scale when pressed — tactile without being cartoonish.
struct DSPressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(DS.Animations.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DSPressButtonStyle {
    static var dsPress: DSPressButtonStyle { DSPressButtonStyle() }
}

// MARK: - Hover highlight

/// Subtle hover response for sidebar rows and cards.
struct DSHoverModifier: ViewModifier {
    @State private var hovering = false
    var highlight: Color = .primary.opacity(0.05)

    func body(content: Content) -> some View {
        content
            .background(hovering ? highlight : .clear, in: .rect(cornerRadius: DS.Radii.sm))
            .onHover { hovering in
                withAnimation(DS.Animations.smooth) { self.hovering = hovering }
            }
    }
}

extension View {
    func dsHover(highlight: Color = .primary.opacity(0.05)) -> some View {
        modifier(DSHoverModifier(highlight: highlight))
    }
}

// MARK: - Section header

struct DSSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DS.Typography.sectionHeader)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
