//
//  ViewController.swift
//  CBAssistiveTouchExample
//
//  Created by yyjim on 2019/10/14.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    private let inputTextField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.darkGray

        inputTextField.backgroundColor = UIColor.white
        inputTextField.frame = CGRect(x: 20, y: 50, width: 320, height: 44)
        view.addSubview(inputTextField)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        inputTextField.resignFirstResponder()
    }
}

