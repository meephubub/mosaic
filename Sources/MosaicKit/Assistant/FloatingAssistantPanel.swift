import AppKit
import SwiftUI

/// A transparent, borderless, non-activating panel that hosts the notch and
/// chat. All AppKit windowing lives here — SwiftUI views never touch NSWindow.
final class FloatingAssistantPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func present(at frame: NSRect) {
        setFrame(frame, display: true)
        orderFrontRegardless()
    }

    func dismiss() {
        orderOut(nil)
    }
}
