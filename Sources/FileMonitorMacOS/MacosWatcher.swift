//
// aus der Technik, on 15.05.23.
// https://www.ausdertechnik.de
//

import Foundation
import FileMonitorShared

#if os(macOS)
public final class MacosWatcher: WatcherProtocol {
    public var delegate: WatcherDelegate?
    let fileWatcher: FileWatcher
    private var lastFiles: [URL] = []

    public init(paths: [URL]) throws {
        fileWatcher = FileWatcher(paths.map(\.path))
        fileWatcher.queue = DispatchQueue.global()
        lastFiles = try Self.getCurrentFiles(in: paths)

        fileWatcher.callback = { [self] event throws in
            if let url = URL(string: event.path), url.isDirectory == false {
                let currentFiles = try Self.getCurrentFiles(in: paths)

                let removedFiles = getDifferencesInFiles(lhs: lastFiles, rhs: currentFiles)
                let addedFiles = getDifferencesInFiles(lhs: currentFiles, rhs: lastFiles)
                let changeSetCount = addedFiles.count - removedFiles.count

                // new file in folder is a change, yet
                if (event.fileModified || event.fileChange) && changeSetCount == 0 {
                    self.delegate?.fileDidChanged(event: FileChangeEvent.changed(file: url))
                } else if event.fileRemoved && changeSetCount < 0 {
                    self.delegate?.fileDidChanged(event: FileChangeEvent.deleted(file: url))
                } else if event.fileCreated {
                    self.delegate?.fileDidChanged(event: FileChangeEvent.added(file: url))
                } else {
                    if removedFiles.isEmpty == false {

                    }
                    self.delegate?.fileDidChanged(event: FileChangeEvent.changed(file: url))
                }

                lastFiles = currentFiles
            }
        }
    }

    convenience public init(directory: URL) throws {
        try self.init(paths: [directory])
    }

    deinit {
        stop()
    }

    public func observe() throws {
        fileWatcher.start()
    }

    public func stop() {
        fileWatcher.stop();
    }
}
#endif
