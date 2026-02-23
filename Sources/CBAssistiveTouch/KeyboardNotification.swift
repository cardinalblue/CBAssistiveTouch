//
//  KeyboardNotification.swift
//  CBAssistiveTouch
//
//  Created by yyjim on 2019/10/14.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

/// Refined version of https://gist.github.com/kristopherjohnson/13d5f18b0d56b0ea9242
/// Wrapper for the NSNotification userInfo values associated with a keyboard notification.
///
/// It provides properties that retrieve userInfo dictionary values with these keys:
///
/// - UIKeyboardFrameBeginUserInfoKey
/// - UIKeyboardFrameEndUserInfoKey
/// - UIKeyboardAnimationDurationUserInfoKey
/// - UIKeyboardAnimationCurveUserInfoKey

public struct KeyboardNotification {
    static let validNotificationNames: [Notification.Name] = [
        UIResponder.keyboardWillShowNotification,
        UIResponder.keyboardDidShowNotification,
        UIResponder.keyboardWillHideNotification,
        UIResponder.keyboardDidHideNotification,
        UIResponder.keyboardWillChangeFrameNotification,
        UIResponder.keyboardDidChangeFrameNotification
    ]

    let notification: Notification
    private var info: [AnyHashable: Any] {
        notification.userInfo ?? [:]
    }

    /// Initializer
    ///
    /// :param: notification Keyboard-related notification
    public init?(_ notification: Notification) {
        guard KeyboardNotification.validNotificationNames.contains(notification.name) else {
            return nil
        }
        self.notification = notification
    }

    /// Start frame of the keyboard in screen coordinates
    public var beginFrame: CGRect {
        info[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
    }

    /// End frame of the keyboard in screen coordinates
    public var endFrame: CGRect {
        info[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
    }

    /// Keyboard animation duration
    public var animationDuration: Double {
        info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
    }

    /// Keyboard animation curve
    ///
    /// Note that the value returned by this method may not correspond to a
    /// UIViewAnimationCurve enum value. It returns value 7.
    /// https://stackoverflow.com/questions/7327249/ios-how-to-convert-uiviewanimationcurve-to-uiviewanimationoptions
    public var animationCurve: UIView.AnimationCurve? {
        let rawValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int
        return UIView.AnimationCurve(rawValue: rawValue)
    }

    public var animationOptions: UIView.AnimationOptions {
        if let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
            return UIView.AnimationOptions(rawValue: UInt(curve << 16))
        } else {
            return UIView.AnimationOptions.curveEaseInOut
        }
    }

    /// Start frame of the keyboard in coordinates of specified view
    ///
    /// :param: view UIView to whose coordinate system the frame will be converted
    /// :returns: frame rectangle in view's coordinate system
    public func frameBeginForView(view: UIView) -> CGRect {
        view.convert(beginFrame, from: view.window)
    }

    /// End frame of the keyboard in coordinates of specified view
    ///
    /// :param: view UIView to whose coordinate system the frame will be converted
    /// :returns: frame rectangle in view's coordinate system
    public func frameEndForView(view: UIView) -> CGRect {
        view.convert(endFrame, from: view.window)
    }
}
