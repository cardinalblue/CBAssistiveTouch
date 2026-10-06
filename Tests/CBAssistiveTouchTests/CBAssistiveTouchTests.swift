import XCTest
@testable import CBAssistiveTouch

/// The floating element is positioned purely from a center + the current bounding box, so these
/// two functions are what has to stay correct when the screen resizes.
final class AssistiveTouchGeometryTests: XCTestCase {
    /// Safe-area-inset, margin-inset portrait screen.
    private let bounding = CGRect(x: 16, y: 63, width: 361, height: 700)

    func testZeroWidthFillsTheBoundingBox() {
        let size = AssistiveTouchViewController.resolvedSize(
            for: CGSize(width: 0, height: 320),
            bounding: bounding
        )
        XCTAssertEqual(size, CGSize(width: 361, height: 320))
    }

    func testOversizedContentIsClampedToTheBoundingBox() {
        let size = AssistiveTouchViewController.resolvedSize(
            for: CGSize(width: 9_999, height: 9_999),
            bounding: bounding
        )
        XCTAssertEqual(size, bounding.size)
    }

    func testCenterOutsideTheBoundingBoxSnapsToTheNearestEdge() {
        // Center way off the right edge, as if the screen just rotated under a stale position.
        let frame = AssistiveTouchViewController.clampedFrame(
            for: CGSize(width: 44, height: 44),
            center: CGPoint(x: 2_000, y: 400),
            bounding: bounding
        )
        XCTAssertEqual(frame.maxX, bounding.maxX, accuracy: 0.001)
        XCTAssertEqual(frame.midY, 400, accuracy: 0.001)
        XCTAssertTrue(bounding.contains(frame))
    }

    /// Even a center well inside the box gets pulled to an edge — the element always sticks,
    /// and only the *nearest* edge moves.
    func testCenterInsideTheBoundingBoxStillSticksToTheNearestEdge() {
        let frame = AssistiveTouchViewController.clampedFrame(
            for: CGSize(width: 44, height: 44),
            center: CGPoint(x: 200, y: 100),
            bounding: bounding
        )
        XCTAssertEqual(frame.minY, bounding.minY, accuracy: 0.001)
        XCTAssertEqual(frame.midX, 200, accuracy: 0.001)
    }

    /// Unfolding onto a wider display keeps the element on the side it was on, instead of leaving it
    /// at the same absolute x, which is mid-screen on the wider display.
    func testAnchorKeepsTheSideOnAWiderBoundingBox() {
        let size = CGSize(width: 44, height: 44)
        let rightEdge = CGPoint(x: bounding.maxX - size.width / 2, y: 400)
        let anchor = AssistiveTouchViewController.anchor(for: rightEdge, size: size, bounding: bounding)

        let wide = CGRect(x: 16, y: 40, width: 760, height: 780)
        let frame = AssistiveTouchViewController.clampedFrame(
            for: size,
            center: AssistiveTouchViewController.center(for: anchor, size: size, bounding: wide),
            bounding: wide
        )
        XCTAssertEqual(frame.maxX, wide.maxX, accuracy: 0.001)
    }
}
