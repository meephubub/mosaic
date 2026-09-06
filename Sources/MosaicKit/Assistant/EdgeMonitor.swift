import AppKit
import Foundation

/// Assistant visibility phases driven by cursor proximity.
enum AssistantPhase: Equatable {
    case hidden
    case notch
    case chat
}

/// Monitors global mouse movement and drives the assistant phase. Uses
/// `NSEvent.addGlobalMonitorForEvents` (no Accessibility permission needed for
/// mouse events) with hysteresis + debounce instead of a polling loop.
@MainActor
final class EdgeMonitor {
    var onUpdate: (@MainActor (AssistantPhase, AssistantEdge) -> Void)?

    private let geometry = EdgeGeometry()
    private var monitor: Any?
    private var localMonitor: Any?
    private var hideTask: Task<Void, Never>?
    private(set) var activeEdge: AssistantEdge = .left
    private(set) var phase: AssistantPhase = .hidden
    private(set) var cursorPoint: CGPoint = .zero

    private var screens: [ScreenFrame] {
        NSScreen.screens.map { ScreenFrame(frame: $0.frame) }
    }

    func start() {
        guard monitor == nil else { return }
        let handler: (NSEvent) -> Void = { [weak self] _ in
            guard let self else { return }
            let point = NSEvent.mouseLocation
            Task { @MainActor in
                self.handleCursor(at: point)
            }
        }
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged],
            handler: handler
        )

        // Global monitors do not receive events delivered to Mosaic itself.
        // Keep a local monitor for cursor movement over the panel/workspace.
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] event in
            guard let self else { return event }
            let point = NSEvent.mouseLocation
            Task { @MainActor in
                self.handleCursor(at: point)
            }
            return event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        monitor = nil
        localMonitor = nil
    }

    /// Tests can drive this directly with synthetic points.
    func handleCursor(at point: CGPoint) {
        cursorPoint = point
        guard let screen = ScreenFrame.screen(containing: point, screens: screens) else { return }

        // Multi-monitor: the edge evaluated is the one on the cursor's screen.
        let isNearLeft = geometry.proximity(of: point, on: screen, edge: .left) == .inside
        let isNearRight = geometry.proximity(of: point, on: screen, edge: .right) == .inside

        switch phase {
        case .chat:
            return // chat stays open; dismissal is user-driven

        case .notch:
            let leftZone = activeEdge == .left
            let left = leftZone ? geometry.hasLeft(of: point, on: screen, edge: .left) : false
            let right = !leftZone ? geometry.hasLeft(of: point, on: screen, edge: .right) : false
            if (leftZone && left) || (!leftZone && right) {
                scheduleHide()
            } else {
                hideTask?.cancel()
                hideTask = nil
            }

        case .hidden:
            if isNearLeft {
                showNotch(edge: .left)
            } else if isNearRight {
                showNotch(edge: .right)
            }
        }
    }

    private func showNotch(edge: AssistantEdge) {
        hideTask?.cancel()
        activeEdge = edge
        setPhase(.notch)
    }

    private func scheduleHide() {
        guard hideTask == nil else { return }
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled else { return }
            hideTask = nil
            if phase == .notch {
                setPhase(.hidden)
            }
        }
    }

    /// Called by the controller when the user opens or closes the chat.
    func setPhase(_ newPhase: AssistantPhase) {
        phase = newPhase
        onUpdate?(phase, activeEdge)
    }
}
