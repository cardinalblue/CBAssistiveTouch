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
        // While presenting or dismissing the animator owns the frame. Stomping it here is what made
        // the content jump to its full size at both ends of the transition.
        // Deliberately not `transitionCoordinator == nil`: that is also non-nil during a rotation,
        // which would leave the content stranded at its old frame as the screen resizes.
        guard !presentedViewController.isBeingPresented,
              !presentedViewController.isBeingDismissed else {
            return
        }
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

/// Scales the content between the collapsed button's frame and its expanded frame.
///
/// Animates a transform rather than the frame, so the content's Auto Layout is not re-run on every
/// frame of a 44pt-to-full-width animation.
final class AssistiveTouchContentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let duration: TimeInterval
    private let collapsedFrame: () -> CGRect

    init(isPresenting: Bool, duration: TimeInterval, collapsedFrame: @escaping () -> CGRect) {
        self.isPresenting = isPresenting
        self.duration = duration
        self.collapsedFrame = collapsedFrame
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let finalFrame = transitionContext.finalFrame(for: toViewController)
        toView.frame = finalFrame
        transitionContext.containerView.addSubview(toView)

        toView.transform = Self.transform(from: finalFrame, to: collapsedFrame())
        toView.alpha = 0

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            toView.transform = .identity
            toView.alpha = 1
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let startFrame = fromView.frame

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            fromView.transform = Self.transform(from: startFrame, to: self.collapsedFrame())
            fromView.alpha = 0
        } completion: { _ in
            // The same content view controller is presented again next time, so hand it back clean.
            fromView.transform = .identity
            fromView.alpha = 1
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    /// Transform mapping `frame` onto `target`, applied about the view's centre.
    private static func transform(from frame: CGRect, to target: CGRect) -> CGAffineTransform {
        guard frame.width > 0, frame.height > 0 else {
            return .identity
        }
        return CGAffineTransform(
            translationX: target.midX - frame.midX,
            y: target.midY - frame.midY
        )
        .scaledBy(x: target.width / frame.width, y: target.height / frame.height)
    }
}
