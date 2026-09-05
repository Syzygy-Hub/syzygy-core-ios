// MARK: - App Lifecycle
// Foreground/background state tracking, lifecycle observers, lifecycle-aware scoping.

import SyzygyFoundation

/// Application lifecycle state.
public enum AppLifecycleState: Sendable {
    case active
    case inactive
    case background
}

/// Observes app lifecycle transitions.
public protocol AppLifecycleObserver: Sendable {
    func onStateChange(_ state: AppLifecycleState)
}

/// Tracks the app's current lifecycle state and notifies registered observers.
public final class AppLifecycleTracker: @unchecked Sendable {
    // TODO: observer registry, state tracking, lifecycle-aware scoping
    public init() {}
}
