import Testing
import Foundation
@testable import SyzygyCore

#if canImport(UIKit)
import UIKit
#endif

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

    // MARK: - FIX 10: iOS lifecycle timestamps

    @Test func lastTransitionAtIsNilBeforeAnyTransition() {
        let tracker = AppLifecycleTracker()
        #expect(tracker.lastTransitionAt == nil)
    }

    @Test func lastTransitionAtIsSetAfterTransition() {
        let tracker = AppLifecycleTracker()
        tracker.transition(to: .active)
        #expect(tracker.lastTransitionAt != nil)
    }

    // MARK: - ITEM 4: fromNotificationCenter factory

#if canImport(UIKit)
    @Test func fromNotificationCenterWiresLifecycleNotifications() {
        let center = NotificationCenter()
        let tracker = AppLifecycleTracker.fromNotificationCenter(center)
        #expect(tracker.currentState == .inactive)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        #expect(tracker.currentState == .active)
    }
#endif
}
