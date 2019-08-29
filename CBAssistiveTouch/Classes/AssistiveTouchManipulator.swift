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

    var assistiveTouchFrame: CGRect {
        didSet {
            onChange?(assistiveTouchFrame)
        }
    }
    let bounding: CGRect
    let layout: AssitiveTouchLayout

    private var prevPoint: CGPoint?
    private var center: CGPoint {
        get {
            return CGPoint(x: assistiveTouchFrame.midX, y: assistiveTouchFrame.midY)
        }
        set {
            var newFrame = assistiveTouchFrame
            newFrame.origin.x = newValue.x - newFrame.width / 2
            newFrame.origin.y = newValue.y - newFrame.height / 2
            self.assistiveTouchFrame = newFrame
            print("new frame \(newFrame)")
        }
    }
    private lazy var layoutBounding: CGRect = {
        bounding.insetBy(dx: layout.margin, dy: layout.margin)
    }()

    var onChange: ((CGRect) -> Void)?

    init(assistiveTouchFrame: CGRect, bounding: CGRect, layout: AssitiveTouchLayout) {
        self.assistiveTouchFrame = assistiveTouchFrame
        self.bounding = bounding
        self.layout = layout
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

    private func align(to bounding: CGRect) {
        var newFrame = assistiveTouchFrame
        let center = CGPoint(x: assistiveTouchFrame.midX, y: assistiveTouchFrame.midY)

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
        self.assistiveTouchFrame = newFrame
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
        align(to: layoutBounding)
    }

    func touchesEnded(_ touches: Set<Touch>) {
        move(with: touches)
        align(to: layoutBounding)
    }

}
