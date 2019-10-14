//
//  ATLayoutAttributes.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import Foundation

public protocol AssitiveTouchLayout {

    var safeAreaInsets: UIEdgeInsets { get }
    var customView: UIView? { get }
    var margin: CGFloat { get }
    var animationDuration: TimeInterval { get }
    var assitiveTouchSize: CGSize { get }
    var assitiveTouchInitialPosition: CGPoint { get }

}

public class DefaultAssitiveTouchLayout: AssitiveTouchLayout {

    public var customView: UIView? = nil

    public var animationDuration: TimeInterval = 0.25

    public var margin: CGFloat = 20

    public var assitiveTouchSize: CGSize = CGSize(width: 60, height: 60)

    public var assitiveTouchInitialPosition: CGPoint {
        let screen = UIScreen.main.bounds
        return CGPoint(x: screen.width - assitiveTouchSize.width / 2 - margin, y: screen.midY)
    }

    public var safeAreaInsets: UIEdgeInsets

    public init(keyWindow: UIWindow?) {
        safeAreaInsets = keyWindow?.cbat_safeAreaInsetCompatible ?? UIEdgeInsets.zero
    }

}
