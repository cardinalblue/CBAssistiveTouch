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
    var margin: CGFloat { get }
    var animationDuration: TimeInterval { get }
    var assitiveTouchSize: CGSize { get }
    var assitiveTouchInitialPosition: CGPoint { get }

}

struct DefaultAssitiveTouchLayout: AssitiveTouchLayout {

    private let keyWindow: UIWindow?

    var animationDuration: TimeInterval {
        return 0.25
    }

    var margin: CGFloat {
        return 2
    }

    var assitiveTouchSize: CGSize {
        return CGSize(width: 60, height: 60)
    }

    var assitiveTouchInitialPosition: CGPoint {
        let screen = UIScreen.main.bounds
        return CGPoint(x: screen.width - assitiveTouchSize.width / 2 - margin, y: screen.midY)
    }

    var safeAreaInsets: UIEdgeInsets {
        return keyWindow?.safeAreaInsets ?? UIEdgeInsets.zero
    }

    init(keyWindow: UIWindow?) {
        self.keyWindow = keyWindow
    }

}
