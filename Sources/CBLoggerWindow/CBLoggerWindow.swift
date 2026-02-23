import CBAssistiveTouch
import UIKit

@MainActor
public final class CBLoggerWindow {
    /// An event emitted by CBLoggerWindow to notify the caller of internal state changes.
    public enum Event {
        case toggleRequested
        case logCountChanged(Int)
        case clearRequested
    }

    /// A custom action button displayed in the logger console toolbar.
    ///
    /// Use this to add app-specific buttons alongside the built-in CLEAR and HIDE buttons.
    ///
    /// ```swift
    /// let resetAction = CBLoggerWindow.Action(title: "RESET") {
    ///     // restore defaults
    /// }
    /// let window = CBLoggerWindow(applicationWindow: appWindow, actions: [resetAction])
    /// ```
    public struct Action {
        public let title: String
        public let handler: () -> Void

        public init(title: String, handler: @escaping @MainActor () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    public var onEvent: ((Event) -> Void)?
    public private(set) var isVisible = false

    private let assistiveTouch: AssistiveTouch
    private let logger: CBLogger
    private let consoleViewController: CBLoggerConsoleViewController

    public init(
        applicationWindow: UIWindow,
        preferredContentSize: CGSize? = nil,
        margin: CGFloat = 16,
        floatingToolView: UIView? = nil,
        actions: [Action] = []
    ) {
        let resolvedLogger = CBInMemoryLogger()
        self.logger = resolvedLogger

        let consoleViewController = CBLoggerConsoleViewController(
            logger: resolvedLogger,
            actions: actions
        )
        consoleViewController.preferredContentSize = preferredContentSize ?? CGSize(
            width: max(280, applicationWindow.bounds.width - 32),
            height: 320
        )
        self.consoleViewController = consoleViewController

        let layout = DefaultAssistiveTouchLayout(applicationWindow: applicationWindow)
        layout.margin = margin
        layout.customView = floatingToolView ?? Self.makeDefaultFloatingToolView()
        if let customView = layout.customView {
            layout.assistiveTouchSize = customView.bounds.size
        }

        self.assistiveTouch = AssistiveTouch(
            applicationWindow: applicationWindow,
            layout: layout,
            contentViewController: consoleViewController
        )

        consoleViewController.onEvent = { [weak self] event in
            self?.handleConsoleEvent(event)
        }
        _ = consoleViewController.view
    }

    public func show() {
        assistiveTouch.show()
        isVisible = true
    }

    public func hide() {
        assistiveTouch.hide()
        isVisible = false
    }

    public func toggle() {
        assistiveTouch.toggle()
        isVisible.toggle()
    }

    public func toggleContent() {
        assistiveTouch.toggleContent()
    }

    public func log(event: String, parameters: [String: Any]? = nil) {
        logger.log(event: event, parameters: parameters)
    }

    public func replaceLogs(with events: [String]) {
        logger.replaceAll(with: events)
    }

    private func handleConsoleEvent(_ event: CBLoggerConsoleViewController.Event) {
        switch event {
        case .toggleRequested:
            toggleContent()
            onEvent?(.toggleRequested)

        case .logCountChanged(let count):
            onEvent?(.logCountChanged(count))

        case .clearRequested:
            onEvent?(.clearRequested)
        }
    }

    public static func makeDefaultFloatingToolView() -> UIView {
        let size = CGSize(width: 44, height: 44)
        let container = UIView(frame: CGRect(origin: .zero, size: size))
        container.backgroundColor = .clear
        container.layer.cornerRadius = size.width / 2
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blurView.frame = container.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = size.width / 2
        blurView.layer.masksToBounds = true
        container.addSubview(blurView)

        let tintView = UIView(frame: blurView.bounds)
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tintView.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        blurView.contentView.addSubview(tintView)

        let imageView = UIImageView(image: UIImage(systemName: "apple.terminal"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 12, y: 12, width: 20, height: 20)
        container.addSubview(imageView)

        return container
    }
}
