//
//  CBConsoleViewController.swift
//  CBAssistiveTouchExample
//
//  Created by yyjim on 2019/8/28.
//  Copyright © 2019 Cardinalblue. All rights reserved.
//

import UIKit

private class LoggerCell: UITableViewCell {

    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CBConsoleViewController: UIViewController {

    private enum Action: String, CaseIterable {
        case clear = "CLEAR"
        case reset = "RESET"
    }

    var items: [String] = ["xxx", "yyy", "ccc"]

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputTextField = UITextField(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupTopBar()
        setupTableView()
        setupInputTextField()
        setupButton()

        log(event: "gg", parameters: ["name": "xx", "count": 0])
        log(event: "gg", parameters: ["name": "yy", "count": 1])
        log(event: "gg", parameters: ["name": "zz", "count": 2])
    }

    public func log(event: String, parameters: [String: Any]? = nil) {

        var eventString = event
        if let parameters = parameters {
            // Casting parameters to 'AnyObject' to make output look like this format:
            // {
            //    a: 1,
            //    b: 2,
            //    c: 3
            // }
            eventString.append(" \(parameters as AnyObject)")
        }

        items.append(eventString)

        let indexPath = IndexPath(row: items.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    private func setupTopBar() {
        let bar = UIView()
        bar.backgroundColor = UIColor.lightGray
        bar.autoresizingMask = [.flexibleWidth,
                                .flexibleLeftMargin,
                                .flexibleRightMargin,
                                .flexibleBottomMargin]
        bar.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 30)
        view.addSubview(bar)
    }

    private func setupButton() {
        var originX = CGFloat(8.0)
        
        Action.allCases.forEach { (action) in
            let v = makeView(for: action)
            v.sizeToFit()

            var frame = v.bounds
            frame.origin = CGPoint(x: originX, y: 2 + (30 - frame.height) / 2)
            v.frame = frame
            view.addSubview(v)

            originX += v.bounds.width + 8
        }
    }


    private func makeView(for action: Action) -> UIView {
        let b = UIButton(type: .custom)
        b.setTitle(action.rawValue, for: .normal)
        b.titleLabel?.font = UIFont(name: "DINCondensed-Bold", size: 14)

        switch action {
        case .clear:
            b.addTarget(self, action: #selector(handleClearButtonPressed), for: .touchUpInside)
        case .reset:
            b.addTarget(self, action: #selector(handleResetButtonPressed), for: .touchUpInside)
        }
        return b
    }

    @objc private func handleResetButtonPressed() {
        // reset
    }

    @objc private func handleClearButtonPressed() {
        clear()
    }

    private func setupInputTextField() {
        view.addSubview(inputTextField)
        inputTextField.textColor = UIColor.white
        inputTextField.font = UIFont.systemFont(ofSize: 12)
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.leftViewMode = .always
        inputTextField.tintColor = .white
        inputTextField.leftView = { () -> UILabel in
            let v = UILabel(frame: CGRect(x: 0, y: 0, width: 12, height: 30))
            v.text = ">"
            v.font = UIFont.systemFont(ofSize: 12)
            v.textColor = .white
            return v
        }()
        inputTextField.clearButtonMode = .always
        inputTextField.autocapitalizationType = .none
        inputTextField.autocorrectionType = .no
        inputTextField.delegate = self
        inputTextField.clearsOnBeginEditing = true
        addAccessory()
        NSLayoutConstraint.activate([
            inputTextField.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            inputTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            inputTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputTextField.rightAnchor.constraint(equalTo: view.rightAnchor),
            inputTextField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private let accessory: UIView = {
        let accessoryView = UIView(frame: .zero)
        accessoryView.backgroundColor = .lightGray
        accessoryView.alpha = 0.6
        return accessoryView
    }()

    private func addAccessory() {
        accessory.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 45)
        inputTextField.inputAccessoryView = accessory
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 22.0
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(LoggerCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    private func clear() {
        items.removeAll()
        tableView.reloadData()
    }
}

extension CBConsoleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! LoggerCell
        cell.label.text = items[indexPath.row]
        cell.label.textColor = UIColor.white
        cell.backgroundColor = .clear
        return cell
    }

}


extension CBConsoleViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            log(event: text)
        }
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }

}
