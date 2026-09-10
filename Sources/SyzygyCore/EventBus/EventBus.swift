// MARK: - Event Bus
// Typed publish/subscribe channels with scoped subscriptions and async dispatch.

import Foundation

/// A typed event bus for decoupled pub/sub communication.
/// Subscribers only receive events matching their registered type.
public final class EventBus: @unchecked Sendable {
    private let lock = NSLock()
    private var handlers: [String: [(UUID, Any)]] = [:]

    /// Creates a new event bus.
    public init() {}

    /// Publishes an event to all subscribers registered for its type.
    /// - Parameter event: The event to publish.
    public func publish<E: Sendable>(_ event: E) {
        let key = String(describing: E.self)
        lock.lock()
        let entries = handlers[key] ?? []
        lock.unlock()
        for (_, handler) in entries {
            if let typed = handler as? @Sendable (E) -> Void {
                typed(event)
            }
        }
    }

    /// Subscribes to events of the specified type.
    /// - Parameters:
    ///   - type: The event type to subscribe to.
    ///   - handler: A closure invoked when an event of this type is published.
    /// - Returns: A `SubscriptionToken` that cancels the subscription on `cancel()` or `deinit`.
    public func subscribe<E: Sendable>(to type: E.Type, handler: @escaping @Sendable (E) -> Void) -> SubscriptionToken {
        let key = String(describing: E.self)
        let id = UUID()
        lock.lock()
        handlers[key, default: []].append((id, handler))
        lock.unlock()
        return SubscriptionToken { [weak self] in
            guard let self else { return }
            self.lock.lock()
            self.handlers[key]?.removeAll { $0.0 == id }
            self.lock.unlock()
        }
    }
}

/// Token returned from a subscription; cancel to unsubscribe.
/// The subscription is automatically cancelled when the token is deallocated.
public final class SubscriptionToken: @unchecked Sendable {
    private let lock = NSLock()
    private var _isCancelled = false
    private let onCancel: @Sendable () -> Void

    /// Whether this subscription has been cancelled.
    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCancelled
    }

    init(onCancel: @escaping @Sendable () -> Void) {
        self.onCancel = onCancel
    }

    /// Cancels the subscription.
    public func cancel() {
        lock.lock()
        guard !_isCancelled else {
            lock.unlock()
            return
        }
        _isCancelled = true
        lock.unlock()
        onCancel()
    }

    deinit {
        if !_isCancelled {
            onCancel()
        }
    }
}
