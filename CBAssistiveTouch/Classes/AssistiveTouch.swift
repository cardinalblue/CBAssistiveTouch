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

    let applicationWindow: UIWindow?
    let contentViewController: UIViewController?

    private lazy var window: AssistiveTouchWindow = {
        let frame = CGRect(x: 0, y: 0,
                           width: layout.assitiveTouchSize.width,
                           height: layout.assitiveTouchSize.height)
        let window = AssistiveTouchWindow(frame: frame)
        window.center = layout.assitiveTouchInitialPosition
        window.windowLevel = UIWindow.Level.init(CGFloat.greatestFiniteMagnitude)
        window.backgroundColor = .clear
        window.rootViewController = AssistiveTouchViewController(assistiveTouchWindow: window, layout: layout,
                                                                 contentViewController: contentViewController)
        window.layer.masksToBounds = true
        return window
    }()

    private let layout: AssitiveTouchLayout

    public init(applicationWindow: UIWindow?, layout: AssitiveTouchLayout, contentViewController: UIViewController?) {
        self.applicationWindow = applicationWindow
        self.layout = layout
        self.contentViewController = contentViewController
    }

    public convenience init(applicationWindow: UIWindow?, contentViewController: UIViewController?) {
        self.init(applicationWindow: applicationWindow,
                  layout: DefaultAssitiveTouchLayout(applicationWindow: applicationWindow),
                  contentViewController: contentViewController)
    }

    public func show() {
        maskVisibleWindow()
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

    private func maskVisibleWindow() {
        window.makeKeyAndVisible()
        applicationWindow?.makeKey()
    }

}
