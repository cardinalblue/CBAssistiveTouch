import Combine
import CBAssistiveTouch
import SwiftUI
import UIKit

final class CBLoggerConsoleViewController: UIViewController {
    enum Action {
        case toggleRequested
        case logCountChanged(Int)
        case clearRequested
        case resetRequested
    }

    private enum Section {
        case main
    }

    private struct LogItem: Hashable {
        let id: Int
        let text: String
    }

    var onAction: ((Action) -> Void)?

    private let logger: CBLogger
    @Published private var entries: [String] = []
    private var subscriptions = Set<AnyCancellable>()

    private let toolBarView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var dataSource: UITableViewDiffableDataSource<Section, LogItem>?
    private var toolbarHostingController: UIHostingController<CBLoggerToolbarView>?

    private let toolbarHeight: CGFloat = 30

    init(logger: CBLogger) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        setUpTopBar()
        setUpTableView()
        setUpBindings()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        toolBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: toolbarHeight)
        toolbarHostingController?.view.frame = toolBarView.bounds

        let tableY = toolBarView.frame.maxY
        let tableHeight = max(0, view.bounds.height - tableY)
        tableView.frame = CGRect(x: 0, y: tableY, width: view.bounds.width, height: tableHeight)
    }

    private func setUpBindings() {
        entries = logger.entries

        $entries.sink { [weak self] entries in
            guard let self else {
                return
            }
            onAction?(.logCountChanged(entries.count))
            update(entries: entries, scrollToBottom: true)
        }
        .store(in: &subscriptions)

        logger.onEntriesChanged = { [weak self] entries in
            self?.entries = entries
        }
    }

    private func setUpTopBar() {
        toolBarView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        toolBarView.autoresizingMask = [
            .flexibleWidth,
            .flexibleLeftMargin,
            .flexibleRightMargin,
            .flexibleBottomMargin
        ]
        toolBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: toolbarHeight)
        view.addSubview(toolBarView)

        let toolbarView = CBLoggerToolbarView(
            onClear: { [weak self] in self?.handleClearButtonPressed() },
            onReset: { [weak self] in self?.handleResetButtonPressed() },
            onToggle: { [weak self] in self?.handleToggleButtonPressed() }
        )

        let hostingController = UIHostingController(rootView: toolbarView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = toolBarView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addChild(hostingController)
        toolBarView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        toolbarHostingController = hostingController
    }

    private func setUpTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 22
        tableView.rowHeight = UITableView.automaticDimension
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(CBLoggerCell.self, forCellReuseIdentifier: "Cell")

        tableView.contentInsetAdjustmentBehavior = .never

        dataSource = UITableViewDiffableDataSource<Section, LogItem>(
            tableView: tableView
        ) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            guard let loggerCell = cell as? CBLoggerCell else {
                return cell
            }
            loggerCell.label.text = item.text
            return cell
        }

        view.addSubview(tableView)
    }

    private func handleResetButtonPressed() {
        onAction?(.resetRequested)
    }

    private func handleToggleButtonPressed() {
        onAction?(.toggleRequested)
    }

    private func handleClearButtonPressed() {
        logger.clear()
        onAction?(.clearRequested)
    }

    private func update(entries: [String], scrollToBottom: Bool) {
        guard let dataSource, isViewLoaded else {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, LogItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            entries.enumerated().map { LogItem(id: $0.offset, text: $0.element) },
            toSection: .main
        )

        dataSource.apply(snapshot, animatingDifferences: view.window != nil) { [weak self] in
            guard scrollToBottom else {
                return
            }
            DispatchQueue.main.async {
                self?.scrollToBottomIfPossible()
            }
        }
    }

    private func scrollToBottomIfPossible() {
        let count = tableView.numberOfRows(inSection: 0)
        guard count > 0 else {
            return
        }

        let indexPath = IndexPath(row: count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
}

extension CBLoggerConsoleViewController: ATPassthroughable {
    func shouldPassthroughTouch(at point: CGPoint) -> Bool {
        if toolBarView.frame.contains(point) {
            return false
        }

        let bounds = view.bounds
        let rect = CGRect(x: bounds.maxX - 44, y: 0, width: 44, height: bounds.height)
        return !rect.contains(point)
    }
}

private final class CBLoggerCell: UITableViewCell {
    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct CBLoggerToolbarView: View {
    let onClear: () -> Void
    let onReset: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Logger Console")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 8)

            toolbarButton("CLEAR", action: onClear)
            toolbarButton("RESET", action: onReset)
            toolbarButton("HIDE", action: onToggle)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private func toolbarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
