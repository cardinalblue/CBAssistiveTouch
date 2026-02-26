//
//  AssistiveTouchDemoController.swift
//  Demo
//
//  Created by yyjim on 19/02/2026.
//  Copyright © 2026 Cardinal Blue. All rights reserved.
//

import CBLoggerWindow
import UIKit

@MainActor
final class AssistiveTouchDemoController: ObservableObject {
    @Published private(set) var isAssistiveTouchVisible = false
    @Published private(set) var logCount = 0
    @Published private(set) var lastEvent = "No events yet"

    private var loggerWindowController: CBLoggerWindow?
    private var sampleIndex = 0

    private let sampleEvents = [
        "Debug menu opened",
        "Canvas render completed",
        "Upload queue synced",
        "Premium flag enabled"
    ]

    func configureIfNeeded() {
        guard loggerWindowController == nil else {
            return
        }
        guard let window = UIApplication.shared.cbatKeyWindow else {
            return
        }

        let loggerWindowController = CBLoggerWindow(
            applicationWindow: window,
            preferredContentSize: CGSize(
                width: max(280, window.bounds.width - 32),
                height: 320
            ),
            margin: 16,
            actions: [
                CBLoggerWindow.Action(title: "SPAM") { [weak self] in
                    self?.spamLogs()
                },
                CBLoggerWindow.Action(title: "RESET") { [weak self] in
                    self?.resetDemoState()
                }
            ]
        )
        loggerWindowController.onEvent = { [weak self] event in
            guard let self else {
                return
            }

            switch event {
            case .toggleRequested:
                break

            case .logCountChanged(let newCount):
                self.logCount = newCount

            case .clearRequested:
                self.lastEvent = "Logs cleared"
                self.logCount = 0
            }
        }

        self.loggerWindowController = loggerWindowController
        loggerWindowController.show()
        isAssistiveTouchVisible = true
        appendInitialLogsIfNeeded()
    }

    func toggleAssistiveTouch() {
        configureIfNeeded()
        guard let loggerWindowController else {
            return
        }
        loggerWindowController.toggle()
        isAssistiveTouchVisible.toggle()
    }

    func toggleConsole() {
        configureIfNeeded()
        loggerWindowController?.toggleContent()
    }

    func showConsole() {
        configureIfNeeded()
        loggerWindowController?.showContent()
    }

    func hideConsole() {
        configureIfNeeded()
        loggerWindowController?.hideContent()
    }

    func addLog(_ event: String, params: [String: Any]? = nil) {
        configureIfNeeded()

        let sanitized = event.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else {
            return
        }

        loggerWindowController?.log(event: sanitized, parameters: params)
        lastEvent = sanitized
    }

    func logSampleEvent() {
        let event = sampleEvents[sampleIndex % sampleEvents.count]
        sampleIndex += 1
        addLog(event, params: ["index": sampleIndex])
    }

    func spamLogs() {
        for i in 1...10 {
            addLog("Spam log entry", params: ["i": i])
        }
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
            loggerWindowController?.replaceLogs(with: initialLogs)
            logCount = initialLogs.count
            return
        }

        guard logCount == 0 else {
            return
        }
        initialLogs.forEach { loggerWindowController?.log(event: $0) }
        lastEvent = initialLogs.last ?? lastEvent
    }
}

private extension UIApplication {
    var cbatKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}
