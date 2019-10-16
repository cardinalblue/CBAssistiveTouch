//
//  AssistiveTouchWindow.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/10/16.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import Foundation

protocol AssistiveTouchWindowDelegate: class {
    func assistiveTouchWindowShouldPassthroughTouch(window: AssistiveTouchWindow, at: CGPoint) -> Bool
}

class AssistiveTouchWindow: UIWindow {

    weak var delegate: AssistiveTouchWindowDelegate?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let delegate = delegate {
            return delegate.assistiveTouchWindowShouldPassthroughTouch(window: self, at: point) ? false : true
        }
        return super.point(inside: point, with: event)
    }

}
