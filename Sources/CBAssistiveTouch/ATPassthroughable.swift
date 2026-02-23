//
//  ATPassthroughable.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/10/16.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import Foundation

public protocol ATPassthroughable {
    /// Returns a Boolean value indicating whether the receiver should passthorugh the specified point.
    /// - Parameter at: a touch point that in the receiver's coordinate system.
    func shouldPassthroughTouch(at: CGPoint) -> Bool
}
