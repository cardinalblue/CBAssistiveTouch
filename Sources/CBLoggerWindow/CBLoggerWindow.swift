import CBAssistiveTouch
import UIKit

@MainActor
public final class CBLoggerWindow {
    public enum Action {
        case toggleRequested
        case logCountChanged(Int)
        case clearRequested
        case resetRequested
    }

    public var onAction: ((Action) -> Void)?
    public private(set) var isVisible = false

    private let assistiveTouch: AssistiveTouch
    private let logger: CBLogger
    private let consoleViewController: CBLoggerConsoleViewController

    public init(
        applicationWindow: UIWindow,
        preferredContentSize: CGSize? = nil,
        margin: CGFloat = 16,
        floatingToolView: UIView? = nil
    ) {
        let resolvedLogger = CBInMemoryLogger()
        self.logger = resolvedLogger

        let consoleViewController = CBLoggerConsoleViewController(logger: resolvedLogger)
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

        consoleViewController.onAction = { [weak self] action in
            self?.handleConsoleAction(action)
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

    private func handleConsoleAction(_ action: CBLoggerConsoleViewController.Action) {
        switch action {
        case .toggleRequested:
            toggleContent()
            onAction?(.toggleRequested)
        case .logCountChanged(let count):
            onAction?(.logCountChanged(count))
        case .clearRequested:
            onAction?(.clearRequested)
        case .resetRequested:
            onAction?(.resetRequested)
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
