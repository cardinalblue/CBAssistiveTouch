import Foundation

@MainActor
protocol CBLogger: AnyObject {
    var entries: [String] { get }
    var onEntriesChanged: (([String]) -> Void)? { get set }

    func append(_ entry: String)
    func replaceAll(with entries: [String])
    func clear()
}

extension CBLogger {
    func log(event: String, parameters: [String: Any]? = nil) {
        var eventString = event
        if let parameters {
            eventString.append(" \(parameters as AnyObject)")
        }
        append(eventString)
    }
}

@MainActor
final class CBInMemoryLogger: CBLogger {
    private(set) var entries: [String]
    var onEntriesChanged: (([String]) -> Void)?

    init(entries: [String] = []) {
        self.entries = entries
    }

    func append(_ entry: String) {
        entries.append(entry)
        onEntriesChanged?(entries)
    }

    func replaceAll(with entries: [String]) {
        self.entries = entries
        onEntriesChanged?(self.entries)
    }

    func clear() {
        entries.removeAll()
        onEntriesChanged?(entries)
    }
}
