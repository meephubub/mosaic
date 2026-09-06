import XCTest
@testable import MosaicKit

final class EdgeGeometryTests: XCTestCase {
    let geometry = EdgeGeometry()
    // A 1440x900 screen at AppKit origin (0,0 bottom-left).
    let screen = ScreenFrame(minX: 0, maxX: 1440, minY: 0, maxY: 900)

    func testLeftEdgeInside() {
        let point = CGPoint(x: 10, y: 450)
        XCTAssertEqual(geometry.proximity(of: point, on: screen, edge: .left), .inside)
    }

    func testLeftEdgeOutside() {
        let point = CGPoint(x: 100, y: 450)
        XCTAssertEqual(geometry.proximity(of: point, on: screen, edge: .left), .outside)
    }

    func testRightEdgeInside() {
        let point = CGPoint(x: 1430, y: 450)
        XCTAssertEqual(geometry.proximity(of: point, on: screen, edge: .right), .inside)
    }

    func testRightEdgeOutside() {
        let point = CGPoint(x: 1300, y: 450)
        XCTAssertEqual(geometry.proximity(of: point, on: screen, edge: .right), .outside)
    }

    func testVerticalBandExclusion() {
        // Same x as inside-case but far from vertical middle.
        let point = CGPoint(x: 10, y: 100)
        XCTAssertEqual(geometry.proximity(of: point, on: screen, edge: .left), .outside)
    }

    func testHasLeftUsesHysteresis() {
        // Within show distance but beyond hide distance? No: show < hide,
        // so hasLeft is only true past the larger hide distance.
        let point = CGPoint(x: 30, y: 450)
        XCTAssertFalse(geometry.hasLeft(of: point, on: screen, edge: .left))
        let farPoint = CGPoint(x: 60, y: 450)
        XCTAssertTrue(geometry.hasLeft(of: farPoint, on: screen, edge: .left))
    }

    func testScreenContainingPicksCorrectScreen() {
        let screens = [
            ScreenFrame(minX: 0, maxX: 1440, minY: 0, maxY: 900),
            ScreenFrame(minX: 1440, maxX: 3600, minY: 0, maxY: 900)
        ]
        let point = CGPoint(x: 2000, y: 400)
        let containing = ScreenFrame.screen(containing: point, screens: screens)
        XCTAssertEqual(containing, screens[1])
    }

    func testScreenContainingNilWhenOutside() {
        let screens = [ScreenFrame(minX: 0, maxX: 1440, minY: 0, maxY: 900)]
        XCTAssertNil(ScreenFrame.screen(containing: CGPoint(x: 2000, y: 400), screens: screens))
    }
}
