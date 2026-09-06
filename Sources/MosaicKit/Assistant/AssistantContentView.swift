import SwiftUI

/// The SwiftUI content of the floating panel: either the compact edge notch or
/// the expanded chat. The frame change + matchedGeometryEffect produces the
/// notch→chat morph.
struct AssistantContentView: View {
    @Bindable var controller: FloatingAssistantController

    var body: some View {
        ZStack(alignment: controller.activeEdge == .left ? .leading : .trailing) {
            switch controller.phase {
            case .hidden:
                EmptyView()

            case .notch:
                NotchSurface(controller: controller)
                    .transition(.asymmetric(
                        insertion: .move(edge: controller.activeEdge == .left ? .leading : .trailing)
                            .combined(with: .opacity),
                        removal: .move(edge: controller.activeEdge == .left ? .leading : .trailing)
                            .combined(with: .opacity)
                    ))

            case .chat:
                ChatSurface(controller: controller)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6, anchor: controller.activeEdge == .left ? .leading : .trailing)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.6, anchor: controller.activeEdge == .left ? .leading : .trailing)
                            .combined(with: .opacity)
                    ))
            }
        }
        .animation(DS.Animations.softSpring, value: controller.phase)
    }
}

// MARK: - Notch

/// The compact protrusion from the screen edge containing the mascot.
struct NotchSurface: View {
    @Bindable var controller: FloatingAssistantController

    private var edge: AssistantEdge { controller.activeEdge }

    var body: some View {
        Button {
            controller.openChat()
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                if edge == .right {
                    chevron
                }
                BotView(mood: .alert, size: 26)
                if edge == .left {
                    chevron
                }
            }
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: DS.Radii.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radii.lg)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
        }
        .buttonStyle(.dsPress)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: edge == .left ? .leading : .trailing)
        .accessibilityLabel("Open Mosaic assistant")
    }

    private var chevron: some View {
        Image(systemName: edge == .left ? "chevron.compact.right" : "chevron.compact.left")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Chat surface

/// The expanded floating chat card.
struct ChatSurface: View {
    @Bindable var controller: FloatingAssistantController

    var body: some View {
        ChatView(controller: controller.chat)
            .frame(width: 360, height: 480)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: DS.Radii.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radii.xl)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: controller.activeEdge == .left ? .leading : .trailing)
    }
}
