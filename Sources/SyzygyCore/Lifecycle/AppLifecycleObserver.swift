// MARK: - App Lifecycle
// Foreground/background state tracking, lifecycle observers, lifecycle-aware scoping.

import Foundation
import SyzygyFoundation

#if canImport(UIKit)
import UIKit
#endif

/// Application lifecycle state.
public enum AppLifecycleState: Sendable, Equatable {
    case active
    case inactive
    case background
    case terminated
}

/// Observes app lifecycle transitions.
public protocol AppLifecycleObserver: AnyObject {
    /// Called when the lifecycle state changes.
    func lifecycleDidChange(to state: AppLifecycleState)
}

/// Tracks the app's current lifecycle state and notifies registered observers.
public final class AppLifecycleTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var _state: AppLifecycleState = .inactive
    private var observers: [ObjectIdentifier: WeakObserver] = [:]
    private var _notificationTokens: [Any] = []

    /// The timestamp of the last lifecycle transition, or `nil` if no transition has occurred.
    public private(set) var lastTransitionAt: SyzygyTimestamp?

    private struct WeakObserver {
        weak var value: (any AppLifecycleObserver)?
    }

    /// The current lifecycle state.
    public var currentState: AppLifecycleState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    /// Creates a lifecycle tracker.
    public init() {}

#if canImport(UIKit)
    /// Creates an `AppLifecycleTracker` wired to `UIApplication` notifications.
    ///
    /// Observation tokens are kept alive on the returned tracker for its lifetime.
    /// - Parameter notificationCenter: The notification center to observe (default: `.default`).
    /// - Returns: A configured `AppLifecycleTracker`.
    public static func fromNotificationCenter(_ notificationCenter: NotificationCenter = .default) -> AppLifecycleTracker {
        let tracker = AppLifecycleTracker()
        let pairs: [(Notification.Name, AppLifecycleState)] = [
            (UIApplication.didBecomeActiveNotification,    .active),
            (UIApplication.willResignActiveNotification,   .inactive),
            (UIApplication.didEnterBackgroundNotification, .background),
            (UIApplication.willEnterForegroundNotification,.inactive),
            (UIApplication.willTerminateNotification,      .terminated),
        ]
        let tokens: [Any] = pairs.map { (name, state) in
            notificationCenter.addObserver(forName: name, object: nil, queue: nil) { [weak tracker] _ in
                tracker?.transition(to: state)
            }
        }
        tracker.lock.lock()
        tracker._notificationTokens = tokens
        tracker.lock.unlock()
        return tracker
    }
#endif

    /// Adds an observer (held weakly) that will be notified of state changes.
    /// - Parameter observer: The observer to add.
    public func addObserver(_ observer: any AppLifecycleObserver) {
        let id = ObjectIdentifier(observer)
        lock.lock()
        observers[id] = WeakObserver(value: observer)
        lock.unlock()
    }

    /// Removes an observer.
    /// - Parameter observer: The observer to remove.
    public func removeObserver(_ observer: any AppLifecycleObserver) {
        let id = ObjectIdentifier(observer)
        lock.lock()
        observers.removeValue(forKey: id)
        lock.unlock()
    }

    /// Transitions to a new state and notifies all observers.
    /// - Parameter state: The new lifecycle state.
    public func transition(to state: AppLifecycleState) {
        lock.lock()
        _state = state
        lastTransitionAt = SyzygyTimestamp.now()
        // Clean up nil references and collect live observers
        var liveObservers: [any AppLifecycleObserver] = []
        observers = observers.filter { _, weak in weak.value != nil }
        for (_, weak) in observers {
            if let observer = weak.value {
                liveObservers.append(observer)
            }
        }
        lock.unlock()
        for observer in liveObservers {
            observer.lifecycleDidChange(to: state)
        }
    }
}
