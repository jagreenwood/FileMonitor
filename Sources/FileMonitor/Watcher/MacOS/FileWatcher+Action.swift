//
// aus der Technik, on 16.05.23.
// Based on: https://github.com/eonist/FileWatcher/tree/master
//

#if os(macOS)
import Cocoa
/**
 * Actions
 */
extension FileWatcher {
    /**
    * Start listening for FSEvents
    */
    public func start() {
        guard !hasStarted else { return } // -- make sure we are not already listening!
        var context = FSEventStreamContext(
                version: 0,
                info: Unmanaged.passUnretained(self).toOpaque(),
                retain: retainCallback,
                release: releaseCallback,
                copyDescription: nil
        )
        streamRef = FSEventStreamCreate(
                kCFAllocatorDefault,
                eventCallback,
                &context,
                filePaths as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                0,
                UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )
        selectStreamScheduler()
        FSEventStreamStart(streamRef!)
    }
    /**
    * Stop listening for FSEvents
    */
    public func stop() {
        guard hasStarted else { return } // -- make sure we are indeed listening!
        FSEventStreamStop(streamRef!)
        FSEventStreamInvalidate(streamRef!)
        FSEventStreamRelease(streamRef!)
        streamRef = nil
    }
}
#endif