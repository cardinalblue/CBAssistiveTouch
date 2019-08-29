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

    unowned let assistiveTouchWindow: UIWindow
    let layout: AssitiveTouchLayout

    private lazy var assistiveTouchView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        v.backgroundColor = UIColor.green
        return v
    }()

    private var manipulator: AssistiveTouchManipulator?

    // MARK: Object lifecycle

    init(assistiveTouchWindow: UIWindow, layout: AssitiveTouchLayout) {
        self.assistiveTouchWindow = assistiveTouchWindow
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(assistiveTouchView)

        setupGestures()
    }

    private func setupGestures() {
        let paneGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
        assistiveTouchView.addGestureRecognizer(paneGesture)
    }

    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            beginDragging()
            let bounding = assistiveTouchWindow.bounds.inset(by: assistiveTouchWindow.safeAreaInsets)
                                                      .insetBy(dx: layout.margin, dy: layout.margin)
            manipulator = AssistiveTouchManipulator(itemFrame: presentingView.frame,
                                                    bounding: bounding)
            manipulator?.onChange = { [unowned self] frame in
                self.assistiveTouchView.frame = frame
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

    private func beginDragging() {
        let frame = UIScreen.main.bounds

        // We are going to change window frame to cover entire screen, and the coordinate space will be changed.
        // To keep the assistive touch at same position, we have to covert the current position to new cooridnate space.
        let referenceCoordinateSpace: UICoordinateSpace = UIView(frame: frame)
        let newCenter = view.convert(assistiveTouchView.center, to: referenceCoordinateSpace)

        // NOTE: Change winodw's frame will aslo change the viewController's frame.
        assistiveTouchWindow.frame = frame
        assistiveTouchView.center = newCenter
    }

    private func endDragging() {
        let frame = CGRect(x: 0, y: 0, width: layout.assitiveTouchSize.width, height: layout.assitiveTouchSize.height)

        // NOTE: Change winodw's frame will aslo change the viewController's frame.
        // Change to assistive touch coordinate space, move to assistive touch position.
        assistiveTouchWindow.frame = frame
        assistiveTouchWindow.center = assistiveTouchView.center
        assistiveTouchView.frame = frame
    }


}
