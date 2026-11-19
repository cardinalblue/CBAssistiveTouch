//
//  AssistiveTouchViewController.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

protocol AssistiveTouchContentTransitioning: AnyObject {
    func assistiveTouchWillPresentContent()
    func assistiveTouchWillDismissContent()
}

extension AssistiveTouchContentTransitioning {
    func assistiveTouchWillPresentContent() {}
    func assistiveTouchWillDismissContent() {}
}

/// Root view controller of the always-full-screen `AssistiveTouchWindow`.
///
/// The window is never resized — UIKit keeps it matching its `UIWindowScene`. Everything floating
/// lives in this view controller's coordinate space, positioned from a single stored
/// `floatingCenter`; every frame is derived from it and the *current* bounding box.
class AssistiveTouchViewController: UIViewController {
    unowned let assistiveTouchWindow: AssistiveTouchWindow
    let layout: AssistiveTouchLayout
    let contentViewController: UIViewController?

    /// The floating element's center, in this view controller's coordinate space.
    private var floatingCenter: CGPoint = .zero

    /// Where to move back to once the keyboard hides.
    private var lastFloatingCenter: CGPoint?

    /// Where the floating element sits relative to `bounding` — see `anchor(for:size:bounding:)`.
    /// Only the user moves it; bounding changes re-place the element from it, so it keeps its side.
    private var anchor = CGPoint(x: 1, y: 0.5)

    private struct LayoutEnvironment: Equatable {
        let bounding: CGRect
        let occlusionFrames: [CGRect]
    }

    private var lastLayoutEnvironment: LayoutEnvironment?

    private lazy var contentView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: layout.assistiveTouchSize))
        view.backgroundColor = .clear
        return view
    }()

    private lazy var assistiveTouchView: UIView = {
        let view = layout.customView ?? UIView()
        view.frame = contentView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()

    private var manipulator: AssistiveTouchManipulator?

    // MARK: Object lifecycle

    init(
        assistiveTouchWindow: AssistiveTouchWindow,
        layout: AssistiveTouchLayout,
        contentViewController: UIViewController?
    ) {
        self.assistiveTouchWindow = assistiveTouchWindow
        self.layout = layout
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)

        self.assistiveTouchWindow.delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        contentView.addSubview(assistiveTouchView)
        view.addSubview(contentView)

        setupGestures()
    }

    /// Reacts to every screen size and safe area change — rotation, Split View, iPhone Duo folding —
    /// without looking at interface orientation, which the inner display ignores anyway.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bounding = bounding
        let occlusionFrames = activeOcclusionFrames(in: bounding)
        let environment = LayoutEnvironment(bounding: bounding, occlusionFrames: occlusionFrames)

        // Compare the whole environment, not just the size: when the scene moves between iPhone Duo
        // displays the safe area and reserved regions can settle after the size does.
        guard !bounding.isEmpty, environment != lastLayoutEnvironment else {
            return
        }
        lastLayoutEnvironment = environment

        // Re-place from the anchor, not the old absolute center: an absolute center lands mid-screen
        // on a wider display, and a transient bounding box would push it to whichever side is nearest.
        floatingCenter = Self.center(for: anchor, size: layout.assistiveTouchSize, bounding: bounding)
        let frame = Self.resolvedFrame(
            for: layout.assistiveTouchSize,
            center: floatingCenter,
            bounding: bounding,
            avoiding: occlusionFrames
        )
        floatingCenter = CGPoint(x: frame.midX, y: frame.midY)
        lastFloatingCenter = nil
        contentView.frame = frame
    }

    private func setupGestures() {
        let paneGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
        assistiveTouchWindow.addGestureRecognizer(paneGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(recognizer:)))
        assistiveTouchWindow.addGestureRecognizer(tapGesture)
    }

    // MARK: Geometry

    /// Area the floating element is allowed to occupy, in this view controller's coordinate space.
    /// Vertical edges respect the safe area; horizontal edges use the full container so asymmetric
    /// safe-area insets, such as the iPhone Duo camera region, do not leave a large empty column.
    private var bounding: CGRect {
        Self.boundingRect(
            in: view.bounds,
            safeAreaInsets: view.safeAreaInsets,
            margin: layout.margin
        )
    }

    static func boundingRect(in bounds: CGRect, safeAreaInsets: UIEdgeInsets, margin: CGFloat) -> CGRect {
        bounds.inset(
            by: UIEdgeInsets(
                top: safeAreaInsets.top + margin,
                left: margin,
                bottom: safeAreaInsets.bottom + margin,
                right: margin
            )
        )
    }

    private var contentSize: CGSize {
        guard presentedViewController != nil else {
            return layout.assistiveTouchSize
        }
        return resolvedSize(for: contentViewController?.preferredContentSize ?? .zero)
    }

    private func resolvedSize(for preferredSize: CGSize) -> CGSize {
        Self.resolvedSize(for: preferredSize, bounding: bounding)
    }

    /// A zero dimension means "fill the available space", so content tracks screen size changes.
    /// Anything larger than `bounding` is clamped to it.
    static func resolvedSize(for preferredSize: CGSize, bounding: CGRect) -> CGSize {
        var size = preferredSize
        if size.width <= 0 {
            size.width = bounding.width
        }
        if size.height <= 0 {
            size.height = bounding.height
        }
        return CGSize(
            width: min(size.width, bounding.width),
            height: min(size.height, bounding.height)
        )
    }

    /// Frame of `size` centred on `floatingCenter`, pushed back inside `bounding`.
    /// Pure — it never writes `floatingCenter`, so it is safe to call from any layout pass.
    private func clampedFrame(for size: CGSize) -> CGRect {
        Self.clampedFrame(for: size, center: floatingCenter, bounding: bounding)
    }

    static func clampedFrame(for size: CGSize, center: CGPoint, bounding: CGRect) -> CGRect {
        let frame = CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        let manipulator = AssistiveTouchManipulator(itemFrame: frame, bounding: bounding)
        manipulator.align(to: bounding)
        return manipulator.itemFrame
    }

    /// Returns an edge-aligned frame that avoids active system occlusions whenever possible.
    /// If every same-size placement overlaps, the least-overlapping placement wins.
    private func resolvedFrame(for size: CGSize) -> CGRect {
        let bounding = bounding
        return Self.resolvedFrame(
            for: size,
            center: floatingCenter,
            bounding: bounding,
            avoiding: activeOcclusionFrames(in: bounding)
        )
    }

    static func resolvedFrame(
        for size: CGSize,
        center: CGPoint,
        bounding: CGRect,
        avoiding occlusionFrames: [CGRect]
    ) -> CGRect {
        let clampedFrame = clampedFrame(for: size, center: center, bounding: bounding)
        let occlusionFrames = occlusionFrames.filter { !$0.isEmpty && $0.intersects(bounding) }
        guard !occlusionFrames.isEmpty, size.width <= bounding.width, size.height <= bounding.height else {
            return clampedFrame
        }

        let minimumX = bounding.minX
        let maximumX = bounding.maxX - size.width
        let minimumY = bounding.minY
        let maximumY = bounding.maxY - size.height
        let epsilon: CGFloat = 0.001

        func uniqueClamped(_ values: [CGFloat], minimum: CGFloat, maximum: CGFloat) -> [CGFloat] {
            values.reduce(into: []) { result, value in
                guard value.isFinite else {
                    return
                }
                let clampedValue = min(max(value, minimum), maximum)
                if !result.contains(where: { abs($0 - clampedValue) <= epsilon }) {
                    result.append(clampedValue)
                }
            }
        }

        let xOrigins = uniqueClamped(
            [clampedFrame.minX, minimumX, maximumX]
                + occlusionFrames.flatMap { [$0.minX - size.width, $0.maxX] },
            minimum: minimumX,
            maximum: maximumX
        )
        let yOrigins = uniqueClamped(
            [clampedFrame.minY, minimumY, maximumY]
                + occlusionFrames.flatMap { [$0.minY - size.height, $0.maxY] },
            minimum: minimumY,
            maximum: maximumY
        )

        func overlapArea(of frame: CGRect) -> CGFloat {
            occlusionFrames.reduce(0) { area, occlusionFrame in
                let intersection = frame.intersection(occlusionFrame)
                guard !intersection.isNull else {
                    return area
                }
                return area + max(0, intersection.width) * max(0, intersection.height)
            }
        }

        func movement(of frame: CGRect) -> CGFloat {
            let x = frame.midX - clampedFrame.midX
            let y = frame.midY - clampedFrame.midY
            return x * x + y * y
        }

        func isBetter(_ candidate: CGRect, than current: CGRect) -> Bool {
            let candidateScore = (overlapArea(of: candidate), movement(of: candidate))
            let currentScore = (overlapArea(of: current), movement(of: current))
            if abs(candidateScore.0 - currentScore.0) > epsilon {
                return candidateScore.0 < currentScore.0
            }
            if abs(candidateScore.1 - currentScore.1) > epsilon {
                return candidateScore.1 < currentScore.1
            }
            if abs(candidate.minY - current.minY) > epsilon {
                return candidate.minY < current.minY
            }
            return candidate.minX < current.minX
        }

        var bestFrame = clampedFrame
        for x in xOrigins {
            for y in yOrigins {
                let candidate = CGRect(origin: CGPoint(x: x, y: y), size: size)
                let touchesOuterEdge = abs(candidate.minX - bounding.minX) <= epsilon
                    || abs(candidate.maxX - bounding.maxX) <= epsilon
                    || abs(candidate.minY - bounding.minY) <= epsilon
                    || abs(candidate.maxY - bounding.maxY) <= epsilon
                guard touchesOuterEdge else {
                    continue
                }
                if isBetter(candidate, than: bestFrame) {
                    bestFrame = candidate
                }
            }
        }
        return bestFrame
    }

    private func activeOcclusionFrames(in bounding: CGRect) -> [CGRect] {
        guard #available(iOS 27.1, *) else {
            return []
        }
        return view.reservedRegions(kind: .occlusion)
            .map(\.frame)
            .filter { !$0.isEmpty && $0.intersects(bounding) }
            .sorted {
                ($0.minY, $0.minX, $0.maxY, $0.maxX) < ($1.minY, $1.minX, $1.maxY, $1.maxX)
            }
    }

    /// `center` as a fraction of the area a `size` item's center can move in: x = 1 is the right
    /// edge, y = 0 the top. Unlike a point, it means the same side on any bounding box.
    static func anchor(for center: CGPoint, size: CGSize, bounding: CGRect) -> CGPoint {
        let range = bounding.insetBy(dx: size.width / 2, dy: size.height / 2)
        return CGPoint(
            x: range.width > 0 ? (center.x - range.minX) / range.width : 0.5,
            y: range.height > 0 ? (center.y - range.minY) / range.height : 0.5
        )
    }

    static func center(for anchor: CGPoint, size: CGSize, bounding: CGRect) -> CGPoint {
        let range = bounding.insetBy(dx: size.width / 2, dy: size.height / 2)
        guard !range.isNull else {
            return CGPoint(x: bounding.midX, y: bounding.midY)
        }
        return CGPoint(x: range.minX + anchor.x * range.width, y: range.minY + anchor.y * range.height)
    }

    private var floatingFrame: CGRect {
        resolvedFrame(for: contentSize)
    }

    /// The view currently representing the floating element: the presented content, or the button.
    private var targetView: UIView {
        presentedViewController?.view ?? contentView
    }

    private func applyFloatingFrame(_ frame: CGRect) {
        targetView.frame = frame
    }

    // MARK: Gesture handlers

    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            manipulator = AssistiveTouchManipulator(itemFrame: floatingFrame, bounding: bounding)
            manipulator?.onChange = { [unowned self] frame in
                self.floatingCenter = CGPoint(x: frame.midX, y: frame.midY)
                self.applyFloatingFrame(frame)
            }
            let touch = Touch(identifier: "pan", point: recognizer.location(in: view))
            manipulator?.touchesBegan([touch])

        case .changed:
            let touch = Touch(identifier: "pan", point: recognizer.location(in: view))
            manipulator?.touchesMoved([touch])

        case .ended, .cancelled:
            let touch = Touch(identifier: "pan", point: recognizer.location(in: view))
            UIView.animate(
                withDuration: layout.animationDuration,
                animations: {
                    self.manipulator?.touchesEnded([touch])
                    let frame = self.resolvedFrame(for: self.contentSize)
                    self.floatingCenter = CGPoint(x: frame.midX, y: frame.midY)
                    self.applyFloatingFrame(frame)
                },
                completion: { _ in
                    self.manipulator = nil
                    self.lastFloatingCenter = nil
                    self.anchor = Self.anchor(
                        for: self.floatingCenter,
                        size: self.layout.assistiveTouchSize,
                        bounding: self.bounding
                    )
                }
            )

        default:
            break
        }
    }

    @objc private func handleTapGesture(recognizer: UITapGestureRecognizer) {
        toggleContent()
    }

    // MARK: Content

    func toggleContent() {
        if presentedViewController != nil {
            dismissContent()
        } else {
            presentContent()
        }
    }

    func presentContent() {
        guard let contentViewController, presentedViewController == nil else {
            return
        }
        (contentViewController as? AssistiveTouchContentTransitioning)?.assistiveTouchWillPresentContent()

        contentViewController.modalPresentationStyle = .custom
        contentViewController.transitioningDelegate = self

        contentView.isHidden = true
        present(contentViewController, animated: true)
    }

    func dismissContent() {
        guard let presented = presentedViewController, !presented.isBeingDismissed else {
            return
        }
        (presented as? AssistiveTouchContentTransitioning)?.assistiveTouchWillDismissContent()

        // The content shrinks onto the button, so put the button there before it reappears.
        contentView.frame = resolvedFrame(for: layout.assistiveTouchSize)
        dismiss(animated: true) { [contentView] in
            contentView.isHidden = false
        }
    }

    // MARK: Keyboard

    @objc private func keyboardWillChangeFrame(notification: Notification) {
        guard let keyboard = KeyboardNotification(notification) else {
            return
        }

        let newCenter: CGPoint?

        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            let keyboardFrame = view.convert(keyboard.endFrame, from: nil)
            let yOffset = floatingFrame.maxY - keyboardFrame.minY
            // Return if keyboard doesn't cover the assistiveTouch.
            guard yOffset > 0 else {
                return
            }
            // The keyboard will cover the assisitveTouch. Shift it alongs with the keyboard.
            lastFloatingCenter = floatingCenter
            newCenter = CGPoint(x: floatingCenter.x, y: floatingCenter.y - layout.margin - yOffset)

        case UIResponder.keyboardWillHideNotification:
            newCenter = lastFloatingCenter
            lastFloatingCenter = nil

        default:
            return
        }

        guard let newCenter else {
            return
        }

        UIView.animate(
            withDuration: keyboard.animationDuration,
            delay: 0,
            options: keyboard.animationOptions,
            animations: {
                self.floatingCenter = newCenter
                self.applyFloatingFrame(self.floatingFrame)
            }
        )
    }
}

// MARK: - AssistiveTouchWindowDelegate

extension AssistiveTouchViewController: AssistiveTouchWindowDelegate {
    func assistiveTouchWindowShouldPassthroughTouch(window: AssistiveTouchWindow, at point: CGPoint) -> Bool? {
        let target = targetView
        // Convert to receiver's coordinate system
        let localPoint = window.convert(point, to: target)
        // The window spans the whole screen, so everything outside the floating element must pass through.
        guard target.bounds.contains(localPoint) else {
            return true
        }
        if let passthroughable = presentedViewController as? ATPassthroughable {
            return passthroughable.shouldPassthroughTouch(at: localPoint)
        }
        return false
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension AssistiveTouchViewController: UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = AssistiveTouchPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.frameProvider = { [unowned self] in self.floatingFrame }
        return presentationController
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        makeAnimator(isPresenting: true)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        makeAnimator(isPresenting: false)
    }

    private func makeAnimator(isPresenting: Bool) -> AssistiveTouchContentAnimator {
        AssistiveTouchContentAnimator(
            isPresenting: isPresenting,
            duration: layout.animationDuration,
            collapsedFrame: { [unowned self] in self.resolvedFrame(for: self.layout.assistiveTouchSize) }
        )
    }
}
