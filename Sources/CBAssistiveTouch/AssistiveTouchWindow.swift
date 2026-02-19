//
//  AssistiveTouchWindow.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/10/16.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import Foundation
import UIKit

protocol AssistiveTouchWindowDelegate: AnyObject {
    func assistiveTouchWindowShouldPassthroughTouch(window: AssistiveTouchWindow, at: CGPoint) -> Bool?
}

class AssistiveTouchWindow: UIWindow {

    weak var delegate: AssistiveTouchWindowDelegate?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let delegate = delegate, let shouldPassthrough = delegate.assistiveTouchWindowShouldPassthroughTouch(window: self, at: point) {
            return shouldPassthrough ? false : true
        }
        return super.point(inside: point, with: event)
    }

}
