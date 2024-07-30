//
//  ViewController.swift
//  CBAssistiveTouchExample
//
//  Created by yyjim on 2019/10/14.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import CBAssistiveTouch
import UIKit
import Foundation

class ViewController: UIViewController {

    private let assistiveTouch: AssistiveTouch
    private let inputTextField = UITextField()
    private let toggleButton = UIButton(type: .custom)

    init(assistiveTouch: AssistiveTouch) {
        self.assistiveTouch = assistiveTouch
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.darkGray

        inputTextField.backgroundColor = UIColor.white
        inputTextField.frame = CGRect(x: 20, y: 50, width: 320, height: 44)
        view.addSubview(inputTextField)

        setupToggleButton()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        inputTextField.resignFirstResponder()
    }

    func setupToggleButton() {
        toggleButton.setTitle("Toggle", for: .normal)
        toggleButton.backgroundColor = UIColor.black
        toggleButton.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        toggleButton.center = CGPoint(x: view.bounds.width / 2,
                                      y: view.bounds.height / 2)
        toggleButton.addTarget(self, action: #selector(handleToggleButtonPressed), for: .touchUpInside)
        view.addSubview(toggleButton)
    }

    @objc private func handleToggleButtonPressed() {
        assistiveTouch.toggle()
    }
}

