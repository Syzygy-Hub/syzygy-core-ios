import Testing
@testable import SyzygyCore

@Suite("App Lifecycle Tests")
struct AppLifecycleTests {
    @Test func trackerInitialises() {
        let tracker = AppLifecycleTracker()
        _ = tracker
    }
}
