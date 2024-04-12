//
// aus der Technik, on 15.05.23.
// https://www.ausdertechnik.de
//

import Foundation

public protocol WatcherDelegate {
    func fileDidChanged(event: FileChangeEvent)
}

public protocol WatcherProtocol {
    var delegate: WatcherDelegate? { set get }

    init(directory: URL) throws
    func observe() throws
    func stop()
}

public extension WatcherProtocol {
    @available(*, deprecated, message: "user static WatcherProtocol.getCurrentFiles(in:)")
    func getCurrentFiles(in directory: URL) throws -> [URL] {
        try Self.contentsOfDirectory(directory)
    }

    static func getCurrentFiles(in urls: [URL]) throws -> [URL] {
        try urls.reduce(into: []) { current, next in
            if next.isDirectory {
                try current.append(contentsOf: Self.contentsOfDirectory(next))
            } else {
                current.append(next)
            }
        }
    }

    static func contentsOfDirectory(_ url: URL) throws -> [URL] {
        precondition(url.isDirectory, "Logic error: \(url) is not a directory.")

        return try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.creationDateKey, .typeIdentifierKey],
            options: [.skipsHiddenFiles]
        )
    }

    func getDifferencesInFiles(lhs: [URL], rhs: [URL]) -> Set<URL> {
        Set(lhs).subtracting(rhs)
    }
}
