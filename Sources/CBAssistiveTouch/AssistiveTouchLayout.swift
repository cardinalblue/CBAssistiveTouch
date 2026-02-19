//
//  ATLayoutAttributes.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import Foundation
import UIKit

public protocol AssistiveTouchLayout {
    var safeAreaInsets: UIEdgeInsets { get }
    var customView: UIView? { get }
    var margin: CGFloat { get }
    var animationDuration: TimeInterval { get }
    var assistiveTouchSize: CGSize { get }
    var assistiveTouchInitialPosition: CGPoint { get }
}

public class DefaultAssistiveTouchLayout: AssistiveTouchLayout {
    public var customView: UIView?

    public var animationDuration: TimeInterval = 0.25

    public var margin: CGFloat = 20

    public var assistiveTouchSize = CGSize(width: 60, height: 60)

    public var assistiveTouchInitialPosition: CGPoint {
        let screen = UIScreen.main.bounds
        return CGPoint(x: screen.width - assistiveTouchSize.width / 2 - margin, y: screen.midY)
    }

    public var safeAreaInsets: UIEdgeInsets

    public init(safeAreaInsets: UIEdgeInsets) {
        self.safeAreaInsets = safeAreaInsets
    }

    public convenience init(applicationWindow: UIWindow?) {
        let safeAreaInsets = applicationWindow?.cbat_safeAreaInsetCompatible ?? .zero
        self.init(safeAreaInsets: safeAreaInsets)
    }
}
