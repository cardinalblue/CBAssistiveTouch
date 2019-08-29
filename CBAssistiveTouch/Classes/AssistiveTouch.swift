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

    let application: UIApplication

    private lazy var window: UIWindow = {
        let frame = CGRect(x: 0, y: 0,
                           width: layout.assitiveTouchSize.width,
                           height: layout.assitiveTouchSize.height)
        let window = UIWindow(frame: frame)
        window.center = layout.assitiveTouchInitialPosition
        window.windowLevel = UIWindow.Level.init(CGFloat.greatestFiniteMagnitude)
        window.backgroundColor = .clear
        window.rootViewController = AssistiveTouchViewController(assistiveTouchWindow: window, layout: layout)
        window.layer.masksToBounds = true
        return window
    }()

    private let layout: AssitiveTouchLayout

    public init(application: UIApplication = UIApplication.shared, layout: AssitiveTouchLayout) {
        self.application = application
        self.layout = layout
    }

    public convenience init(application: UIApplication) {
        self.init(application: application, layout: DefaultAssitiveTouchLayout())
    }

    public func show() {
        maskVisibleWindow()
    }

    private func maskVisibleWindow() {
        let keyWindow = application.keyWindow
        window.makeKeyAndVisible()
        keyWindow?.makeKey()
    }

}
