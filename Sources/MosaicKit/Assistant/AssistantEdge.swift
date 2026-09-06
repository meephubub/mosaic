import CoreGraphics

/// Which screen edge the assistant lives on.
enum AssistantEdge: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .left: "Left edge"
        case .right: "Right edge"
        }
    }
}

/// Pure geometry for edge detection — unit-testable without a display.
///
/// Hysteresis: the notch shows when the cursor is within `showDistance` of the
/// edge and hides only once it moves beyond `hideDistance`, preventing flicker.
struct EdgeGeometry: Equatable {
    var showDistance: CGFloat = 24
    var hideDistance: CGFloat = 48
    /// Vertical band (centered) within which the notch appears.
    var verticalBand: CGFloat = 200

    enum Proximity: Equatable {
        case inside
        case outside
    }

    /// Determines proximity for a cursor point on a given screen.
    func proximity(of point: CGPoint, on screen: ScreenFrame, edge: AssistantEdge) -> Proximity {
        guard isInsideVerticalBand(point, screen: screen) else { return .outside }
        switch edge {
        case .left:
            return point.x <= screen.minX + showDistance ? .inside : .outside
        case .right:
            return point.x >= screen.maxX - showDistance ? .inside : .outside
        }
    }

    /// Whether the cursor has clearly left the edge zone (used to hide).
    func hasLeft(of point: CGPoint, on screen: ScreenFrame, edge: AssistantEdge) -> Bool {
        guard isInsideVerticalBand(point, screen: screen) else { return true }
        switch edge {
        case .left:
            return point.x > screen.minX + hideDistance
        case .right:
            return point.x < screen.maxX - hideDistance
        }
    }

    private func isInsideVerticalBand(_ point: CGPoint, screen: ScreenFrame) -> Bool {
        let midY = screen.midY
        let half = verticalBand / 2
        return point.y >= midY - half && point.y <= midY + half
    }
}

/// A display-agnostic screen frame (AppKit-free for testability).
struct ScreenFrame: Equatable {
    var minX: CGFloat
    var maxX: CGFloat
    var minY: CGFloat
    var maxY: CGFloat

    var midY: CGFloat { (minY + maxY) / 2 }

    init(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    init(frame: CGRect) {
        self.init(minX: frame.minX, maxX: frame.maxX, minY: frame.minY, maxY: frame.maxY)
    }

    static func contains(_ point: CGPoint, screens: [ScreenFrame]) -> Bool {
        screens.contains { screen in
            point.x >= screen.minX && point.x <= screen.maxX
                && point.y >= screen.minY && point.y <= screen.maxY
        }
    }

    static func screen(containing point: CGPoint, screens: [ScreenFrame]) -> ScreenFrame? {
        screens.first { screen in
            point.x >= screen.minX && point.x <= screen.maxX
                && point.y >= screen.minY && point.y <= screen.maxY
        }
    }
}
