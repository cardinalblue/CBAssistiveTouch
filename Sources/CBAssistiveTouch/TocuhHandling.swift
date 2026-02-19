//
//  TocuhHandling.swift
//  CBMonitor
//
//  Created by yyjim on 2018/12/28.
//

import UIKit
import Foundation

struct Touch: Hashable {
    let identifier: String
    let point: CGPoint

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(NSValue(cgPoint: point))
    }

    static func == (lhs: Touch, rhs: Touch) -> Bool {
        lhs.identifier == rhs.identifier && lhs.point == rhs.point
    }
}

protocol TouchHandling {
    func touchesBegan(_ touches: Set<Touch>)
    func touchesMoved(_ touches: Set<Touch>)
    func touchesCancelled(_ touches: Set<Touch>)
    func touchesEnded(_ touches: Set<Touch>)
}
