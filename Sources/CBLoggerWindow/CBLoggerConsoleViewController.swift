import Combine
import CBAssistiveTouch
import SwiftUI
import UIKit

final class CBLoggerConsoleViewController: UIViewController {
    enum Event {
        case toggleRequested
        case logCountChanged(Int)
        case clearRequested
    }

    private enum Section {
        case main
    }

    private struct LogItem: Hashable {
        let id: Int
        let text: String
    }

    var onEvent: ((Event) -> Void)?

    private let logger: CBLogger
    private let actions: [CBLoggerWindow.Action]
    @Published private var entries: [String] = []
    private var subscriptions = Set<AnyCancellable>()

    private let toolBarView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var dataSource: UITableViewDiffableDataSource<Section, LogItem>?
    private var toolbarHostingController: UIHostingController<CBLoggerToolbarView>?

    private let toolbarHeight: CGFloat = 30

    init(logger: CBLogger, title: String? = nil, actions: [CBLoggerWindow.Action] = []) {
        self.logger = logger
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        self.title = title
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


    private func setUpBindings() {
        entries = logger.entries

        $entries.sink { [weak self] entries in
            guard let self else {
                return
            }
            onEvent?(.logCountChanged(entries.count))
            update(entries: entries, scrollToBottom: true)
        }
        .store(in: &subscriptions)

        logger.onEntriesChanged = { [weak self] entries in
            self?.entries = entries
        }
    }

    private func setUpTopBar() {
        toolBarView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBarView)

        NSLayoutConstraint.activate([
            toolBarView.topAnchor.constraint(equalTo: view.topAnchor),
            toolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBarView.heightAnchor.constraint(equalToConstant: toolbarHeight)
        ])

        let toolbarView = CBLoggerToolbarView(
            title: title,
            actions: actions,
            onClear: { [weak self] in self?.handleClearButtonPressed() },
            onToggle: { [weak self] in self?.handleToggleButtonPressed() }
        )

        let hostingController = UIHostingController(rootView: toolbarView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        toolBarView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        toolbarHostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: toolBarView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: toolBarView.bottomAnchor)
        ])
    }

    private func setUpTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 16
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
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

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: toolBarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func handleToggleButtonPressed() {
        onEvent?(.toggleRequested)
    }

    private func handleClearButtonPressed() {
        logger.clear()
        onEvent?(.clearRequested)
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
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct CBLoggerToolbarView: View {
    let title: String?
    let actions: [CBLoggerWindow.Action]
    let onClear: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            closeButton(action: onToggle)
            clearButton(action: onClear)

            if let title {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer(minLength: 8)

            ForEach(actions.indices, id: \.self) { index in
                toolbarButton(actions[index].title, action: actions[index].handler)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Button(action: onToggle) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        )
    }

    private func closeButton(action: @escaping () -> Void) -> some View {
        trafficLightButton(color: Color(red: 1.0, green: 0.37, blue: 0.34), action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(red: 0.5, green: 0.0, blue: 0.0))
        }
    }

    private func clearButton(action: @escaping () -> Void) -> some View {
        trafficLightButton(color: Color(red: 1.0, green: 0.74, blue: 0.18), action: action) {
            Image(systemName: "eraser.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.0))
        }
    }

    private func trafficLightButton<Icon: View>(
        color: Color,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay { icon() }
        }
        .buttonStyle(.plain)
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
