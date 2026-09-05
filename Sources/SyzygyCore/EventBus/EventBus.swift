// MARK: - Event Bus
// Typed publish/subscribe channels with scoped subscriptions and async dispatch.

import SyzygyFoundation

/// A typed event bus for decoupled pub/sub communication.
public final class EventBus: @unchecked Sendable {
    // TODO: typed channels, subscribe, publish, scoped subscriptions, async dispatch
    public init() {}
}

/// Token returned from a subscription; cancel to unsubscribe.
public final class SubscriptionToken: Sendable {
    // TODO: cancellation
    public init() {}
}
