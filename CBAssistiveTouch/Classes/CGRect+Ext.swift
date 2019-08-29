//
//  CGRect+Ext.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/29.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

extension CGRect {

    enum Edge {
        case top
        case left
        case bottom
        case right
    }

    func aligned(to rect: CGRect, at edge: Edge) -> CGRect {
        var newRect = self
        switch edge {
        case .top:
            newRect.origin.y = rect.minY
        case .left:
            newRect.origin.x = rect.minX
        case .bottom:
            newRect.origin.y = rect.maxY - newRect.size.height
        case .right:
            newRect.origin.x = rect.maxX - newRect.size.width
        }
        return newRect
    }

}
