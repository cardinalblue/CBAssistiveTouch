//
//  AssistiveTouchViewController.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

class AssistiveTouchViewController: UIViewController {

    unowned let assistiveTouchWindow: AssistiveTouchWindow
    let layout: AssitiveTouchLayout
    let contentViewController: UIViewController?

    private lazy var contentView: UIView = {
        var bounds = CGRect.zero
        bounds.size = layout.assitiveTouchSize
        return UIView(frame: bounds)
    }()

    private var lastWindowPosition: CGPoint?

    private lazy var assistiveTouchView: UIView = {
        let v = UIView(frame: contentView.bounds)
        return layout.customView ?? v
    }()

    private var manipulator: AssistiveTouchManipulator?

    // MARK: Object lifecycle

    init(assistiveTouchWindow: AssistiveTouchWindow, layout: AssitiveTouchLayout, contentViewController: UIViewController?) {
        self.assistiveTouchWindow = assistiveTouchWindow
        self.layout = layout
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)

        self.assistiveTouchWindow.delegate = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.addSubview(assistiveTouchView)
        view.addSubview(contentView)

        setupGestures()
    }

    private func setupGestures() {
        let paneGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
        assistiveTouchWindow.addGestureRecognizer(paneGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(recognizer:)))
        assistiveTouchWindow.addGestureRecognizer(tapGesture)
    }

    // MARK: Gesture handlers

    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            beginDragging()
            let bounding = assistiveTouchWindow.bounds.inset(by: assistiveTouchWindow.cbat_safeAreaInsetCompatible)
                                                      .insetBy(dx: layout.margin, dy: layout.margin)
            manipulator = AssistiveTouchManipulator(itemFrame: presentingView.frame,
                                                    bounding: bounding)
            manipulator?.onChange = { [unowned self] frame in
                self.presentingView.frame = frame
            }
            let location = recognizer.location(in: view)
            let touch = Touch(identifier: "pan", point: location)
            manipulator?.touchesBegan([touch])
        case .changed:
            let location = recognizer.location(in: view)
            let touch = Touch(identifier: "pan", point: location)
            manipulator?.touchesMoved([touch])
        case .ended:
            let location = recognizer.location(in: view)
            let touch = Touch(identifier: "pan", point: location)
            UIView.animate(withDuration: layout.animationDuration, animations: {
                self.manipulator?.touchesEnded([touch])
            }, completion: { _ in
                self.manipulator = nil
                self.endDragging()
            })
        default:
            break
        }
    }

    @objc private func handleTapGesture(recognizer: UITapGestureRecognizer) {
        if presentedViewController != nil {
            dismissContent()
        } else {
            presentContent()
        }
    }

    private var contentSize: CGSize {
        if let presented = presentedViewController {
            return presented.preferredContentSize
        }
        return layout.assitiveTouchSize
    }

    // MARK:

    private func sizeToFitContent(size: CGSize, at center: CGPoint) {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        // NOTE: Change winodw's frame will aslo change the viewController's frame.
        // Change to assistive touch coordinate space, move to assistive touch position.
        assistiveTouchWindow.frame = frame
        assistiveTouchWindow.center = center
        presentingView.frame = frame

        let bounding = UIScreen.main.bounds.inset(by: layout.safeAreaInsets)
                                           .insetBy(dx: layout.margin, dy: layout.margin)
        let manipulator = AssistiveTouchManipulator(itemFrame: assistiveTouchWindow.frame,
                                                    bounding: bounding)
        manipulator.onChange = { [unowned self] frame in
            self.assistiveTouchWindow.frame = frame
        }
        manipulator.align(to: bounding)

    }

    private func presentContent() {
        guard let contentViewController = contentViewController else {
            return
        }

        if #available(iOS 13, *) {
            contentViewController.modalPresentationStyle = .fullScreen
        }

        lastWindowPosition = self.assistiveTouchWindow.center
        present(contentViewController, animated: false, completion: nil)

        UIView.animate(withDuration: layout.animationDuration) {
            self.sizeToFitContent(size: self.contentSize, at: self.assistiveTouchWindow.center)
        }
    }

    private func dismissContent() {
        UIView.animate(withDuration: layout.animationDuration, animations: {
            self.sizeToFitContent(size: self.contentView.bounds.size,
                                  at: self.lastWindowPosition ?? self.assistiveTouchWindow.center)
        }, completion: { _ in
            self.dismiss(animated: false) {
                self.sizeToFitContent(size: self.contentSize, at: self.assistiveTouchWindow.center)
            }
        })
    }

    // MARK: Dragging

    var presentingView: UIView {
        var topMostPresented = presentedViewController
        while topMostPresented?.presentedViewController != nil {
            topMostPresented = topMostPresented?.presentedViewController
        }
        if let presented = topMostPresented {
            return presented.view
        } else {
            return contentView
        }
    }

    private func beginDragging() {
        let frame = UIScreen.main.bounds

        // We are going to change window frame to cover entire screen, and the coordinate space will be changed.
        // To keep the assistive touch at same position, we have to covert the current position to new cooridnate space.
        let referenceCoordinateSpace: UICoordinateSpace = UIView(frame: frame)
        let newCenter = presentingView.superview!.convert(presentingView.center, to: referenceCoordinateSpace)

        // NOTE: Change winodw's frame will aslo change the viewController's frame.
        assistiveTouchWindow.frame = frame
        presentingView.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        presentingView.center = newCenter
    }

    private func endDragging() {
        sizeToFitContent(size: contentSize, at: presentingView.center)
        lastWindowPosition = assistiveTouchWindow.center
    }


    @objc private func keyboardWillChangeFrame(notification: Notification) {
        guard let keyboard = KeyboardNotification(notification) else {
            return
        }

        let target = assistiveTouchWindow
        var newCenter: CGPoint?

        switch notification.name {
        // Show keyboard
        case UIResponder.keyboardWillShowNotification:
            let yOffset = target.frame.maxY - keyboard.endFrame.minY
            // Return if keyboard doesn't cover the assistiveTouch.
            guard yOffset > 0 else {
                return
            }
            // The keyboard will cover the assisitveTouch.
            // Shift it alongs with the keyboard.
            lastWindowPosition = assistiveTouchWindow.center
            newCenter = CGPoint(x: assistiveTouchWindow.center.x,
                                y: assistiveTouchWindow.center.y - layout.margin - yOffset)
        // Hide keyboard
        case UIResponder.keyboardWillHideNotification:
            // Restore to lastWindowPosition
            newCenter = lastWindowPosition
        default:
            return
        }

        if let newCenter = newCenter {
            UIView.animate(withDuration: keyboard.animationDuration,
                           delay: 0,
                           options: keyboard.animationOptions,
                           animations: {
                            target.center = newCenter
            },
                           completion: { _ in
            })
        }
    }
}

extension AssistiveTouchViewController: AssistiveTouchWindowDelegate {

    func assistiveTouchWindowShouldPassthroughTouch(window: AssistiveTouchWindow, at point: CGPoint) -> Bool {
        if let passthroughable = presentedViewController as? ATPassthroughable,
            let presentedView = presentedViewController?.view {
            // Convert to receiver's coordinate system
            let localPoint = window.convert(point, to: presentedView)
            return passthroughable.shouldPassthroughTouch(at: localPoint)
        }
        return false
    }
}
