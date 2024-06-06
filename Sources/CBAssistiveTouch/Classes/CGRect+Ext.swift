//
//  CGRect+Ext.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/29.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

extension CGPoint {

    var magnitude2: CGFloat {
        return x * x + y * y
    }

}

extension CGRect {

    enum Edge: CaseIterable {
        case top
        case left
        case bottom
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    func translation(to rect: CGRect, edge: Edge) -> CGPoint {
        switch edge {
        case .top:
            return CGPoint(x: 0, y: rect.minY - minY)
        case .left:
            return CGPoint(x: rect.minX - minX, y: 0)
        case .bottom:
            return CGPoint(x: 0, y:  rect.maxY - maxY)
        case .right:
            return CGPoint(x: rect.maxX - maxX, y: 0)
        case .topLeft:
            return CGPoint(x: rect.minX - minX, y: rect.minY - minY)
        case .topRight:
            return CGPoint(x: rect.maxX - maxX, y: rect.minY - minY)
        case .bottomLeft:
            return CGPoint(x: rect.minX - minX, y: rect.maxY - maxY)
        case .bottomRight:
            return CGPoint(x: rect.maxX - maxX, y: rect.maxY - maxY)
        }
    }

    func aligned(to rect: CGRect, at edge: Edge) -> CGRect {
        var newRect = self
        let t = translation(to: rect, edge: edge)
        newRect.origin.x += t.x
        newRect.origin.x += t.y
        return newRect
    }

    func closestEdge(to rect: CGRect) -> (edge: Edge, translation: CGPoint)? {
        let edges: [Edge] = Edge.allCases
        return edges.map({ ($0, translation(to: rect, edge: $0)) })
                    .min(by: { $0.1.magnitude2 < $1.1.magnitude2 })
    }

    func minimumTransltion(to rect: CGRect) -> CGPoint {
        guard let info = closestEdge(to: rect) else {
            return .zero
        }
        return info.translation
    }

}
