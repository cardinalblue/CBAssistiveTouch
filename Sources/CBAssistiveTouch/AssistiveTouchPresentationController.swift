//
//  AssistiveTouchPresentationController.swift
//  CBAssistiveTouch
//
//  Copyright © 2026 Cardinalblue. All rights reserved.
//

import UIKit

/// Keeps the presented content pinned to the floating element's frame instead of filling the window.
///
/// `frameProvider` is evaluated on every layout pass, so the frame stays correct no matter whether
/// this container or the presenting view controller lays out first after a screen size change.
final class AssistiveTouchPresentationController: UIPresentationController {
    var frameProvider: () -> CGRect = { .zero }

    override var frameOfPresentedViewInContainerView: CGRect {
        frameProvider()
    }

    override var shouldPresentInFullscreen: Bool {
        false
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
