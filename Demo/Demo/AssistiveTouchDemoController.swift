//
//  AssistiveTouchDemoController.swift
//  Demo
//
//  Created by yyjim on 19/02/2026.
//  Copyright © 2026 Cardinal Blue. All rights reserved.
//

import CBAssistiveTouch
import UIKit

@MainActor
final class AssistiveTouchDemoController: ObservableObject {
    @Published private(set) var isAssistiveTouchVisible = false
    @Published private(set) var logCount = 0
    @Published private(set) var lastEvent = "No events yet"

    private var assistiveTouch: AssistiveTouch?
    private weak var consoleViewController: CBConsoleViewController?
    private var sampleIndex = 0

    private let sampleEvents = [
        "Debug menu opened",
        "Canvas render completed",
        "Upload queue synced",
        "Premium flag enabled"
    ]

    func configureIfNeeded() {
        guard assistiveTouch == nil else {
            return
        }
        guard let window = UIApplication.shared.cbat_keyWindow else {
            return
        }

        let consoleViewController = CBConsoleViewController()
        consoleViewController.preferredContentSize = CGSize(
            width: max(280, window.bounds.width - 32),
            height: 320
        )
        consoleViewController.onAction = { [weak self] action in
            guard let self else {
                return
            }

            switch action {
            case .toggleRequested:
                self.toggleConsole()
            case .logCountChanged(let newCount):
                self.logCount = newCount
            case .clearRequested:
                self.lastEvent = "Logs cleared"
                self.logCount = 0
            case .resetRequested:
                self.resetDemoState()
            }
        }
        _ = consoleViewController.view

        let layout = DefaultAssistiveTouchLayout(applicationWindow: window)
        layout.margin = 16
        layout.customView = Self.makeFloatingToolView()
        if let customView = layout.customView {
            layout.assistiveTouchSize = customView.bounds.size
        }

        let assistiveTouch = AssistiveTouch(
            applicationWindow: window,
            layout: layout,
            contentViewController: consoleViewController
        )

        self.assistiveTouch = assistiveTouch
        self.consoleViewController = consoleViewController

        assistiveTouch.show()
        isAssistiveTouchVisible = true
        appendInitialLogsIfNeeded()
    }

    func toggleAssistiveTouch() {
        configureIfNeeded()
        guard let assistiveTouch else {
            return
        }
        assistiveTouch.toggle()
        isAssistiveTouchVisible.toggle()
    }

    func toggleConsole() {
        configureIfNeeded()
        assistiveTouch?.toggleContent()
    }

    func addLog(_ event: String) {
        configureIfNeeded()

        let sanitized = event.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else {
            return
        }

        consoleViewController?.log(event: sanitized)
        lastEvent = sanitized
    }

    func logSampleEvent() {
        let event = sampleEvents[sampleIndex % sampleEvents.count]
        sampleIndex += 1
        addLog(event)
    }

    func resetDemoState() {
        configureIfNeeded()
        sampleIndex = 0
        appendInitialLogsIfNeeded(forceReplace: true)
        lastEvent = "Demo reset"
    }

    private func appendInitialLogsIfNeeded(forceReplace: Bool = false) {
        let initialLogs = [
            "Demo is ready",
            "Tap the floating tool to open console",
            "Drag the floating tool to reposition"
        ]
        if forceReplace {
            consoleViewController?.replaceLogs(with: initialLogs)
            logCount = initialLogs.count
            return
        }

        guard logCount == 0 else {
            return
        }
        initialLogs.forEach { consoleViewController?.log(event: $0) }
        lastEvent = initialLogs.last ?? lastEvent
    }

    private static func makeFloatingToolView() -> UIView {
        let size = CGSize(width: 56, height: 56)
        let container = UIView(frame: CGRect(origin: .zero, size: size))
        container.backgroundColor = .clear
        container.layer.cornerRadius = size.width / 2
        container.layer.borderWidth = 1.5
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.25
        container.layer.shadowRadius = 10
        container.layer.shadowOffset = CGSize(width: 0, height: 4)

        let imageView = UIImageView(image: UIImage(systemName: "apple.terminal"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(
            x: 15,
            y: 15,
            width: 26,
            height: 26
        )
        container.addSubview(imageView)

        return container
    }
}

private extension UIApplication {
    var cbat_keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}
