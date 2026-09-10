// MARK: - Feature Flags
// Typed feature flags with providers and in-memory overrides.

import Foundation

/// Defines a feature flag with a key, default value, and description.
public struct FeatureFlag<Value: Sendable>: Sendable {
    /// The unique key identifying this flag.
    public let key: String
    /// The default value when no override is set.
    public let defaultValue: Value
    /// A human-readable description of the flag's purpose.
    public let description: String

    /// Creates a feature flag.
    /// - Parameters:
    ///   - key: Unique identifier for the flag.
    ///   - defaultValue: Value used when no provider returns an override.
    ///   - description: Description of the flag.
    public init(key: String, defaultValue: Value, description: String = "") {
        self.key = key
        self.defaultValue = defaultValue
        self.description = description
    }
}

/// A provider that resolves feature flag values.
public protocol FeatureFlagProvider: Sendable {
    /// Returns the current value for the given flag.
    func value<V: Sendable>(for flag: FeatureFlag<V>) -> V
}

/// In-memory feature flag provider with base values and overrides.
/// Overrides take precedence over base values, which take precedence over defaults.
public final class InMemoryFeatureFlagProvider: FeatureFlagProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Any] = [:]
    private var overrides: [String: Any] = [:]

    /// Creates an empty in-memory provider.
    public init() {}

    /// Returns the resolved value for a flag: override > base value > default.
    public func value<V: Sendable>(for flag: FeatureFlag<V>) -> V {
        lock.lock()
        defer { lock.unlock() }
        if let override = overrides[flag.key] as? V {
            return override
        }
        if let base = values[flag.key] as? V {
            return base
        }
        return flag.defaultValue
    }

    /// Sets the base value for a flag.
    /// - Parameters:
    ///   - value: The value to set.
    ///   - flag: The flag to configure.
    public func setValue<V: Sendable>(_ value: V, for flag: FeatureFlag<V>) {
        lock.lock()
        values[flag.key] = value
        lock.unlock()
    }

    /// Sets an override for a flag (takes precedence over base values).
    /// - Parameters:
    ///   - value: The override value.
    ///   - flag: The flag to override.
    public func setOverride<V: Sendable>(_ value: V, for flag: FeatureFlag<V>) {
        lock.lock()
        overrides[flag.key] = value
        lock.unlock()
    }

    /// Clears any override for a flag, falling back to the base value or default.
    /// - Parameter flag: The flag whose override to clear.
    public func clearOverride<V: Sendable>(for flag: FeatureFlag<V>) {
        lock.lock()
        overrides.removeValue(forKey: flag.key)
        lock.unlock()
    }
}
