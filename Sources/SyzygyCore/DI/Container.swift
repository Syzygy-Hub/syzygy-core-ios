// MARK: - DI Container
// Thread-safe dependency injection container with singleton, transient, and scoped lifetimes.

import SyzygyFoundation

/// Lifetime scope for a registered dependency.
public enum Lifetime: Sendable {
    case singleton
    case transient
    case scoped
}

/// Thread-safe dependency injection container.
public final class Container: @unchecked Sendable {
    // TODO: registration storage, resolution, child scopes
    public init() {}
}
