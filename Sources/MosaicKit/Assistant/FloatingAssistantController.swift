import AppKit
import SwiftUI
import Observation
import Combine

/// Owns the floating panel: monitors the cursor, sizes/positions the window
/// for the current phase, and exposes the SwiftUI content. This is the only
/// place AppKit windowing is orchestrated.
@MainActor
@Observable
final class FloatingAssistantController {
    // MARK: Published state

    private(set) var phase: AssistantPhase = .hidden
    private(set) var activeEdge: AssistantEdge = .left
    var enabled: Bool = true
    var preferredEdge: AssistantEdge = .left

    let chat: ChatController

    // MARK: Private

    private let panel: FloatingAssistantPanel
    private let monitor: EdgeMonitor
    private let services: AppServices

    private var stateContinuation: AsyncStream<AssistantPhase>.Continuation?
    lazy var stateStream: AsyncStream<AssistantPhase> = {
        AsyncStream { continuation in
            stateContinuation = continuation
            continuation.yield(phase)
        }
    }()

    private static let notchSize = NSSize(width: 90, height: 120)
    private static let chatSize = NSSize(width: 400, height: 540)

    init(services: AppServices, navigator: WorkspaceNavigator) {
        self.services = services
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panel = FloatingAssistantPanel(contentRect: NSRect(origin: .zero, size: notchSize))
        self.panel = panel
        self.monitor = EdgeMonitor()

        self.chat = ChatController.fromServices(services, navigator: navigator)
        chat.closesFloatingPanel = true

        monitor.onUpdate = { [weak self] phase, edge in
            self?.handleMonitorUpdate(phase: phase, edge: edge)
        }

        panel.contentView = NSHostingView(rootView: AssistantContentView(controller: self))

        NotificationCenter.default.addObserver(
            forName: .openFloatingAssistant, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.openChat()
            }
        }
        NotificationCenter.default.addObserver(
            forName: .closeFloatingAssistant, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closeChat()
            }
        }
        NotificationCenter.default.addObserver(
            forName: .openWorkspaceWindow, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closeChat()
                NotificationCenter.default.post(
                    name: Notification.Name("mosaic.showWorkspaceExternally"), object: nil
                )
            }
        }
    }

    func startMonitoring() {
        monitor.start()
    }

    func stopMonitoring() {
        monitor.stop()
    }

    // MARK: Phase transitions

    private func handleMonitorUpdate(phase newPhase: AssistantPhase, edge: AssistantEdge) {
        activeEdge = edge
        if phase == .chat { return } // chat is user-driven
        setPhase(newPhase, fromMonitor: true)
    }

    func openChat() {
        monitor.setPhase(.chat)
        setPhase(.chat, fromMonitor: false)
    }

    func closeChat() {
        monitor.setPhase(.hidden)
        setPhase(.hidden, fromMonitor: false)
    }

    private func setPhase(_ newPhase: AssistantPhase, fromMonitor: Bool) {
        guard phase != newPhase else { return }
        phase = newPhase
        stateContinuation?.yield(phase)
        layoutPanel()
    }

    // MARK: Layout

    /// Sizes and positions the panel for the current phase on the screen that
    /// contains the cursor (multi-display aware).
    private func layoutPanel() {
        guard let screen = screenForCursor() ?? NSScreen.main else { return }
        let frame = screen.frame
        let visible = screen.visibleFrame

        let size: NSSize
        let origin: NSPoint

        switch phase {
        case .hidden:
            panel.dismiss()
            return

        case .notch:
            size = Self.notchSize
            let x = activeEdge == .left
                ? frame.minX
                : frame.maxX - size.width
            origin = NSPoint(x: x, y: visible.midY - size.height / 2)

        case .chat:
            size = Self.chatSize
            let x = activeEdge == .left
                ? frame.minX + 12
                : frame.maxX - size.width - 12
            origin = NSPoint(x: x, y: visible.midY - size.height / 2)
        }

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        if phase == .chat {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func screenForCursor() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
    }
}
