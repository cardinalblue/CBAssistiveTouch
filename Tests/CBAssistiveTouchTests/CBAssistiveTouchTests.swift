import XCTest
@testable import CBAssistiveTouch

/// The floating element is positioned purely from a center + the current bounding box, so these
/// two functions are what has to stay correct when the screen resizes.
final class AssistiveTouchGeometryTests: XCTestCase {
    /// Safe-area-inset, margin-inset portrait screen.
    private let bounding = CGRect(x: 16, y: 63, width: 361, height: 700)

    func testBoundingUsesVerticalSafeAreaAndHorizontalContainerEdges() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let safeAreaInsets = UIEdgeInsets(top: 24, left: 48, bottom: 20, right: 176)

        let result = AssistiveTouchViewController.boundingRect(
            in: bounds,
            safeAreaInsets: safeAreaInsets,
            margin: 16
        )

        XCTAssertEqual(result, CGRect(x: 16, y: 40, width: 768, height: 524))
    }

    func testDuoRightSafeAreaDoesNotLimitRightEdgeAlignment() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let bounding = AssistiveTouchViewController.boundingRect(
            in: bounds,
            safeAreaInsets: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 176),
            margin: 16
        )

        let frame = AssistiveTouchViewController.clampedFrame(
            for: CGSize(width: 44, height: 44),
            center: CGPoint(x: 2_000, y: bounding.midY),
            bounding: bounding
        )

        XCTAssertEqual(frame.maxX, bounds.maxX - 16, accuracy: 0.001)
    }

    func testCircleAvoidsRightEdgeOcclusionWithoutLeavingTheOuterEdge() {
        let bounding = CGRect(x: 0, y: 0, width: 300, height: 600)
        let size = CGSize(width: 44, height: 44)
        let occlusion = CGRect(x: 250, y: 80, width: 50, height: 60)

        let frame = AssistiveTouchViewController.resolvedFrame(
            for: size,
            center: CGPoint(x: 278, y: 110),
            bounding: bounding,
            avoiding: [occlusion]
        )

        XCTAssertEqual(frame.size, size)
        XCTAssertEqual(frame.maxX, bounding.maxX, accuracy: 0.001)
        XCTAssertEqual(frame.maxY, occlusion.minY, accuracy: 0.001)
        XCTAssertFalse(frame.intersects(occlusion))
    }

    func testFullWidthLoggerMovesVerticallyAroundOcclusion() {
        let bounding = CGRect(x: 0, y: 0, width: 300, height: 600)
        let size = CGSize(width: 300, height: 100)
        let occlusion = CGRect(x: 250, y: 80, width: 50, height: 60)

        let frame = AssistiveTouchViewController.resolvedFrame(
            for: size,
            center: CGPoint(x: 150, y: 100),
            bounding: bounding,
            avoiding: [occlusion]
        )

        XCTAssertEqual(frame.size, size)
        XCTAssertEqual(frame.minY, occlusion.maxY, accuracy: 0.001)
        XCTAssertFalse(frame.intersects(occlusion))
    }

    func testResolvedFrameAvoidsMultipleOcclusionsWhenPossible() {
        let bounding = CGRect(x: 0, y: 0, width: 300, height: 600)
        let size = CGSize(width: 44, height: 44)
        let occlusions = [
            CGRect(x: 250, y: 50, width: 50, height: 100),
            CGRect(x: 100, y: 0, width: 80, height: 40)
        ]

        let frame = AssistiveTouchViewController.resolvedFrame(
            for: size,
            center: CGPoint(x: 278, y: 100),
            bounding: bounding,
            avoiding: occlusions
        )

        XCTAssertEqual(frame.size, size)
        XCTAssertTrue(occlusions.allSatisfy { !frame.intersects($0) })
    }

    func testImpossibleAvoidancePreservesSizeAndMinimizesOverlap() {
        let bounding = CGRect(x: 0, y: 0, width: 100, height: 100)
        let size = CGSize(width: 100, height: 60)
        let occlusions = [
            CGRect(x: 0, y: 0, width: 100, height: 40),
            CGRect(x: 0, y: 70, width: 100, height: 30)
        ]

        let frame = AssistiveTouchViewController.resolvedFrame(
            for: size,
            center: CGPoint(x: 50, y: 50),
            bounding: bounding,
            avoiding: occlusions
        )
        let overlapArea = occlusions.reduce(CGFloat.zero) { area, occlusion in
            let intersection = frame.intersection(occlusion)
            return area + max(0, intersection.width) * max(0, intersection.height)
        }

        XCTAssertEqual(frame.size, size)
        XCTAssertEqual(frame.minY, 20, accuracy: 0.001)
        XCTAssertEqual(overlapArea, 3_000, accuracy: 0.001)
    }

    func testEmptyOcclusionsMatchesExistingClampedFrame() {
        let size = CGSize(width: 44, height: 44)
        let center = CGPoint(x: 200, y: 100)

        let resolved = AssistiveTouchViewController.resolvedFrame(
            for: size,
            center: center,
            bounding: bounding,
            avoiding: []
        )

        XCTAssertEqual(
            resolved,
            AssistiveTouchViewController.clampedFrame(for: size, center: center, bounding: bounding)
        )
    }

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
