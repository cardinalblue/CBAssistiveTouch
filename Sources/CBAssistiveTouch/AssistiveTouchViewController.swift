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

    private var lastLayoutSize: CGSize = .zero

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

    /// Reacts to every screen size change — rotation, Split View, iPhone Duo folding — without
    /// looking at interface orientation, which the inner display ignores anyway.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard view.bounds.size != lastLayoutSize else {
            return
        }
        let isFirstLayout = lastLayoutSize == .zero
        lastLayoutSize = view.bounds.size

        if isFirstLayout {
            let size = layout.assistiveTouchSize
            floatingCenter = CGPoint(x: bounding.maxX - size.width / 2, y: bounding.midY)
        }

        // Snap back inside the new bounding box and make that the new source of truth.
        let frame = floatingFrame
        floatingCenter = CGPoint(x: frame.midX, y: frame.midY)
        lastFloatingCenter = nil
        contentView.frame = clampedFrame(for: layout.assistiveTouchSize)
    }

    private func setupGestures() {
        let paneGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
        assistiveTouchWindow.addGestureRecognizer(paneGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(recognizer:)))
        assistiveTouchWindow.addGestureRecognizer(tapGesture)
    }

    // MARK: Geometry

    /// Area the floating element is allowed to occupy, in this view controller's coordinate space.
    private var bounding: CGRect {
        view.bounds.inset(by: view.safeAreaInsets)
                   .insetBy(dx: layout.margin, dy: layout.margin)
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

    private var floatingFrame: CGRect {
        clampedFrame(for: contentSize)
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
                },
                completion: { _ in
                    self.manipulator = nil
                    self.lastFloatingCenter = nil
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

        // Still collapsed at this point, so this is the button's frame.
        let startFrame = floatingFrame

        present(contentViewController, animated: false) { [unowned self] in
            self.contentView.isHidden = true
            contentViewController.view.frame = startFrame
            UIView.animate(withDuration: self.layout.animationDuration) {
                contentViewController.view.frame = self.floatingFrame
            }
        }
    }

    func dismissContent() {
        guard let presented = presentedViewController else {
            return
        }
        (presented as? AssistiveTouchContentTransitioning)?.assistiveTouchWillDismissContent()

        let endFrame = clampedFrame(for: layout.assistiveTouchSize)
        UIView.animate(
            withDuration: layout.animationDuration,
            animations: {
                presented.view.frame = endFrame
            },
            completion: { [unowned self] _ in
                self.contentView.frame = endFrame
                // Unhide only once the content is gone, so the two never overlap for a frame.
                self.dismiss(animated: false) {
                    self.contentView.isHidden = false
                }
            }
        )
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
}
