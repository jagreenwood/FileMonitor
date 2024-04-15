//
// aus der Technik, on 19.05.23.
//

import Foundation
#if canImport(CInotify)
import CInotify
#endif

#if os(Linux)
class FileSystemWatcher {
    private let dispatchQueue: DispatchQueue
    private let fileDescriptor: Int32
    private let lock = NSLock()
    private var shouldStopWatching: Bool = true

    var urlInfo: [Int32: URL] = [:]

    init() {
        dispatchQueue = DispatchQueue.global(qos: .background)
        fileDescriptor = inotify_init()
        if fileDescriptor < 0 {
            fatalError("Failed to initialize inotify")
        }
    }

    deinit {
        stop()
    }

    func start(urls: [URL], mask: InotifyEventMask, callback: @escaping (InotifyEvent) -> Void) {
        guard !isWatching() else { return }
        shouldWatch(true)

        dispatchQueue.async { [weak self] in
            self?.watch(urls: urls, mask: mask, callback: callback)
        }

        dispatchQueue.activate()
    }

    func stop() {
        shouldWatch(false)
        dispatchQueue.suspend()

        for (watchDescriptor, _) in urlInfo {
            inotify_rm_watch(fileDescriptor, watchDescriptor)
        }

        close(fileDescriptor)
    }
}

private extension FileSystemWatcher {
    func isWatching() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return !shouldStopWatching
    }

    func shouldWatch(_ watch: Bool) {
        lock.lock()
        defer { lock.unlock() }

        shouldStopWatching = !watch
    }

    func watch(urls: [URL], mask: InotifyEventMask, callback: @escaping (InotifyEvent) -> Void) {
        var _urlInfo: [Int32: URL] = [:]
        for url in urls where url.isDirectory {
            let watchDescriptor = inotify_add_watch(fileDescriptor, url.path, mask.rawValue)

            if watchDescriptor > 0 {
                _urlInfo[watchDescriptor] = url
            }
        }

        urlInfo = _urlInfo

        readEvent(fileDescriptor, callback: callback)
    }

    // func checkEvent(_ fileDescriptor: Int32) -> Bool {
    //     var readSet = fd_set()
    //     fdZero(&readSet)
    //     fdSet(fileDescriptor, &readSet)
        
    //     return select(FD_SETSIZE, &readSet, nil, nil, nil) > 0 ? true : false
    // }

    func readEvent(_ fileDescriptor: Int32, callback: @escaping (InotifyEvent) -> Void) {
        let bufferLength: Int = MemoryLayout<inotify_event>.size + Int(NAME_MAX) + 1
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength)

        while isWatching() {
            var currentIndex: Int = 0
            let readLength = read(fileDescriptor, buffer, bufferLength)

            while currentIndex < readLength {
                let _event = withUnsafePointer(to: &buffer[currentIndex]) {
                    $0.withMemoryRebound(to: inotify_event.self, capacity: 1) {
                        $0.pointee
                    }
                }

                if _event.len > 0 {
                    let inotifyEvent = InotifyEvent(
                            watchDescriptor: Int(_event.wd),
                            mask: _event.mask,
                            cookie: _event.cookie,
                            length: _event.len,
                            name: String(cString: buffer + currentIndex + MemoryLayout<inotify_event>.size)
                    )

                    callback(inotifyEvent)
                }

                currentIndex += MemoryLayout<inotify_event>.stride + Int(_event.len)
            }
        }
            
    }
}
#endif
