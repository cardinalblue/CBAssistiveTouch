//
//  Quadrant.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/29.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import Foundation

enum Quadrant {
    case I
    case II
    case III
    case IV

    init(point: CGPoint, bounding: CGRect) {
        // Cartesian coordinate system
        //          +
        //          |
        //     II   |   I
        //          |
        //  +-------O--------+
        //          |
        //     III  |   IV
        //          |
        //          +
        let axesOrigin = CGPoint(x: bounding.minX + bounding.width / 2,
                                 y: bounding.minY + bounding.height / 2)
        // I, IV
        if point.x >= axesOrigin.x {
            if point.y <= axesOrigin.y {
                self = .I
            } else {
                self = .IV
            }
            // II, III
        } else {
            if point.y <= axesOrigin.y {
                self = .II
            } else {
                self = .III
            }
        }
    }
}
