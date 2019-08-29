//
//  AssistiveTouchManipulator.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

class AssistiveTouchManipulator {

    var itemFrame: CGRect {
        didSet {
            onChange?(itemFrame)
        }
    }
    let bounding: CGRect

    private var prevPoint: CGPoint?
    private var center: CGPoint {
        get {
            return CGPoint(x: itemFrame.midX, y: itemFrame.midY)
        }
        set {
            var newFrame = itemFrame
            newFrame.origin.x = newValue.x - newFrame.width / 2
            newFrame.origin.y = newValue.y - newFrame.height / 2
            self.itemFrame = newFrame
        }
    }

    var onChange: ((CGRect) -> Void)?

    init(itemFrame: CGRect, bounding: CGRect) {
        self.itemFrame = itemFrame
        self.bounding = bounding
    }

    private func move(with touches: Set<Touch>) {
        guard let touch = touches.first, let prevPoint = prevPoint else {
            assert(false, "Invaild state, no touch or previous point")
            return
        }
        let currentPoint = touch.point
        let offsetX = currentPoint.x - prevPoint.x
        let offsetY = currentPoint.y - prevPoint.y
        center = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
        self.prevPoint = currentPoint
    }


    /// Align item to edge by checking item's quardrant and comparing the distance of x and y axis.
    ///
    /// - Parameter bounding: Target bounding
    func align(to bounding: CGRect) {
        var newFrame = itemFrame
        let center = CGPoint(x: itemFrame.midX, y: itemFrame.midY)

        // Alignment
        let quadrant = Quadrant(point: center, bounding: bounding)
        switch quadrant {
        case .I:
            if (abs(bounding.maxX - center.x) < abs(bounding.minY - center.y)) {
                newFrame = newFrame.aligned(to: bounding, at: .right)
            } else {
                newFrame = newFrame.aligned(to: bounding, at: .top)
            }
        case .II:
            if (abs(bounding.minX - center.x) < abs(bounding.minY - center.y)) {
                newFrame = newFrame.aligned(to: bounding, at: .left)
            } else {
                newFrame = newFrame.aligned(to: bounding, at: .top)
            }
        case .III:
            if (abs(bounding.minX - center.x) < abs(bounding.maxY - center.y)) {
                newFrame = newFrame.aligned(to: bounding, at: .left)
            } else {
                newFrame = newFrame.aligned(to: bounding, at: .bottom)
            }
        case .IV:
            if (abs(bounding.maxX - center.x) < abs(bounding.maxY - center.y)) {
                newFrame = newFrame.aligned(to: bounding, at: .right)
            } else {
                newFrame = newFrame.aligned(to: bounding, at: .bottom)
            }
        }

        // Validation x-axis
        if newFrame.width < bounding.width {
            newFrame.origin.x = max(newFrame.origin.x, bounding.minX)
            newFrame.origin.x = min(newFrame.origin.x, bounding.maxX - newFrame.size.width)
        }

        // Validation y-axis
        if newFrame.height < bounding.height {
            newFrame.origin.y = max(newFrame.origin.y, bounding.minY)
            newFrame.origin.y = min(newFrame.origin.y, bounding.maxY - newFrame.size.height)
        }

        self.itemFrame = newFrame
    }
}

extension AssistiveTouchManipulator: TouchHandling {

    func touchesBegan(_ touches: Set<Touch>) {
        guard let touch = touches.first else {
            assert(false, "touch can not be nil")
            return
        }
        prevPoint = touch.point
    }

    func touchesMoved(_ touches: Set<Touch>) {
        move(with: touches)
    }

    func touchesCancelled(_ touches: Set<Touch>) {
        move(with: touches)
        align(to: bounding)
    }

    func touchesEnded(_ touches: Set<Touch>) {
        move(with: touches)
        align(to: bounding)
    }

}
