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


    /// Align item to edge
    /// 1. Move the box inside of bouding box.
    /// 2. Calcuating minimum transation to the edge.
    ///
    /// - Parameter bounding: Target bounding
    func align(to bounding: CGRect) {
        var newFrame = itemFrame

        // - Make sure the target it's inside of bounding box
        // Check x-axis
        if newFrame.width <= bounding.width {
            newFrame.origin.x = max(newFrame.origin.x, bounding.minX)
            newFrame.origin.x = min(newFrame.origin.x, bounding.maxX - newFrame.size.width)
        }
        // Check y-axis
        if newFrame.height <= bounding.height {
            newFrame.origin.y = max(newFrame.origin.y, bounding.minY)
            newFrame.origin.y = min(newFrame.origin.y, bounding.maxY - newFrame.size.height)
        }

        // - Calcuating minimum transation to bounding box
        let translation = newFrame.minimumTransltion(to: bounding)
        newFrame.origin.x += translation.x
        newFrame.origin.y += translation.y

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
