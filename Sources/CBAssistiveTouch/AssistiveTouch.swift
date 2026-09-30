//
//  AssistiveTouch.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

public class AssistiveTouch {
    let contentViewController: UIViewController?

    private var assistiveTouchViewController: AssistiveTouchViewController {
        window.rootViewController as! AssistiveTouchViewController
    }

    /// Always spans its scene. The frame is left to UIKit so it tracks rotation, Split View and
    /// iPhone Duo folding on its own; everything floating is positioned inside the root view.
    private lazy var window: AssistiveTouchWindow = {
        let window = AssistiveTouchWindow(windowScene: windowScene)
        window.windowLevel = UIWindow.Level.init(CGFloat.greatestFiniteMagnitude)
        window.backgroundColor = .clear
        window.rootViewController = AssistiveTouchViewController(
            assistiveTouchWindow: window,
            layout: layout,
            contentViewController: contentViewController
        )
        return window
    }()

    let windowScene: UIWindowScene

    private let layout: AssistiveTouchLayout

    /// `contentViewController.preferredContentSize` sizes the presented content. A zero width or
    /// height fills the safe area in that dimension and tracks screen size changes.
    public init(windowScene: UIWindowScene, layout: AssistiveTouchLayout, contentViewController: UIViewController?) {
        self.windowScene = windowScene
        self.layout = layout
        self.contentViewController = contentViewController
    }

    public convenience init(windowScene: UIWindowScene, contentViewController: UIViewController?) {
        self.init(
            windowScene: windowScene,
            layout: DefaultAssistiveTouchLayout(),
            contentViewController: contentViewController
        )
    }

    public func show() {
        window.isHidden = false
    }

    public func hide() {
        window.isHidden = true
    }

    public func toggle() {
        if window.isHidden {
            show()
        } else {
            hide()
        }
    }

    public func showContent() {
        assistiveTouchViewController.presentContent()
    }

    public func hideContent() {
        assistiveTouchViewController.dismissContent()
    }

    public func toggleContent() {
        assistiveTouchViewController.toggleContent()
    }
}
