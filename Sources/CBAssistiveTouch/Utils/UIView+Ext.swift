//
//  UIView+Ext.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/10/14.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit

extension UIView {
    var cbat_safeAreaInsetCompatible: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return safeAreaInsets
        }
        return UIEdgeInsets.zero
    }
}
