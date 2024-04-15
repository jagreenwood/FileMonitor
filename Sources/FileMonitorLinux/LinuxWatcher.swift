//
// aus der Technik, on 15.05.23.
// https://www.ausdertechnik.de
//

import Foundation
import FileMonitorShared
#if canImport(CInotify)
import CInotify
#endif

#if os(Linux)
/// A watcher that observes file changes on Linux.
public struct LinuxWatcher: WatcherProtocol {
    /// The delegate that is called when a file change is detected.
    public var delegate: WatcherDelegate?

    /// The queue on which the delegate is called.
    public var queue = DispatchQueue.main

    var fsWatcher: FileSystemWatcher
    var directories: [URL]

    /// Initializes a new watcher for the given URLs.
    /// - Parameter directories: The directories to observe.
    public init(directories: [URL]) {
        fsWatcher = FileSystemWatcher()
        self.directories = directories
    }

    /// Initializes a new watcher for the given directory.
    /// - Parameter directory: The directory to observe.
    public init(directory: URL) {
        self.init(directories: [directory])
    }

    /// Starts observing the file changes.
    public func observe() throws {
        fsWatcher.start(urls: directories, mask: InotifyEventMask.inAllEvents) { event in
            guard let directory = self.fsWatcher.urlInfo[Int32(event.watchDescriptor)], directory.isDirectory else {
                return
            }

            let url = directory.appendingPathComponent(event.name)

            // Ignore directory changes
            if event.mask & InotifyEventMask.inIsDir.rawValue > 0 { return }

            var urlEvent: FileChangeEvent? = nil

            // File was changed
            if event.mask & InotifyEventMask.inModify.rawValue > 0
                || event.mask & InotifyEventMask.inMoveSelf.rawValue > 0
            {
                urlEvent = FileChangeEvent.changed(file: url)
            }
            // File added
            else if event.mask & InotifyEventMask.inCreate.rawValue > 0
                || event.mask & InotifyEventMask.inMovedTo.rawValue > 0
            {
                urlEvent = FileChangeEvent.added(file: url)
            }
            // File removed
            else if event.mask & InotifyEventMask.inDelete.rawValue > 0
                || event.mask & InotifyEventMask.inDeleteSelf.rawValue > 0
                || event.mask & InotifyEventMask.inMovedFrom.rawValue > 0
            {
                urlEvent = FileChangeEvent.deleted(file: url)
            }

            guard let urlEvent = urlEvent else { return }

            self.queue.async {
                self.delegate?.fileDidChanged(event: urlEvent)
            }
        }
    }

    public func stop() {
        fsWatcher.stop()
    }
}
#endif
