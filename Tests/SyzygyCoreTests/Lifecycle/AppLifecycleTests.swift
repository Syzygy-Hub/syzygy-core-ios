import Testing
@testable import SyzygyCore

@Suite("App Lifecycle Tests")
struct AppLifecycleTests {

    final class SpyObserver: AppLifecycleObserver {
        var states: [AppLifecycleState] = []
        func lifecycleDidChange(to state: AppLifecycleState) {
            states.append(state)
        }
    }

    @Test func initialState() {
        let tracker = AppLifecycleTracker()
        #expect(tracker.currentState == .inactive)
    }

    @Test func transitionNotifiesObserver() {
        let tracker = AppLifecycleTracker()
        let spy = SpyObserver()
        tracker.addObserver(spy)
        tracker.transition(to: .active)
        tracker.transition(to: .background)
        #expect(spy.states == [.active, .background])
        #expect(tracker.currentState == .background)
    }

    @Test func removeObserverStopsNotifications() {
        let tracker = AppLifecycleTracker()
        let spy = SpyObserver()
        tracker.addObserver(spy)
        tracker.transition(to: .active)
        tracker.removeObserver(spy)
        tracker.transition(to: .terminated)
        #expect(spy.states == [.active])
    }

    @Test func weakObserverCleanup() {
        let tracker = AppLifecycleTracker()
        do {
            let spy = SpyObserver()
            tracker.addObserver(spy)
            tracker.transition(to: .active)
            #expect(spy.states == [.active])
        }
        // spy is deallocated; transition should not crash
        tracker.transition(to: .background)
        #expect(tracker.currentState == .background)
    }
}
