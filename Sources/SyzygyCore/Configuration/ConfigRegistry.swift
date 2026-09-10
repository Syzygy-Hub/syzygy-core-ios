// MARK: - Configuration
// In-memory config registry, environment-based switching, and typed config access.

import Foundation
import SyzygyFoundation

// SyzygyEnvironment is provided by SyzygyFoundation:
//   public enum SyzygyEnvironment: String, Equatable, Codable, Sendable {
//       case debug        // replaces Core's former .development
//       case staging
//       case production
//   }

/// A typed configuration key with a name and default value.
public struct ConfigKey<Value: Sendable>: Sendable {
    /// The key name.
    public let name: String
    /// The default value used when no value has been set.
    public let defaultValue: Value

    /// Creates a configuration key.
    public init(name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// In-memory configuration registry with typed access and environment-specific overlays.
public final class ConfigRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var _environment: SyzygyEnvironment
    private var globalValues: [String: Any] = [:]
    private var envValues: [SyzygyEnvironment: [String: Any]] = [:]

    /// The current environment.
    public var environment: SyzygyEnvironment {
        lock.lock()
        defer { lock.unlock() }
        return _environment
    }

    /// Creates a config registry for the given environment.
    /// - Parameter environment: The initial environment (default: `.production`).
    public init(environment: SyzygyEnvironment = .production) {
        self._environment = environment
    }

    /// Returns the value for a key: environment-specific value > global value > default.
    /// - Parameter key: The configuration key to look up.
    /// - Returns: The resolved value.
    public func get<V>(_ key: ConfigKey<V>) -> V {
        lock.lock()
        defer { lock.unlock() }
        if let envVal = envValues[_environment]?[key.name] as? V {
            return envVal
        }
        if let global = globalValues[key.name] as? V {
            return global
        }
        return key.defaultValue
    }

    /// Sets a global value for a key (applies to all environments unless overridden).
    /// - Parameters:
    ///   - key: The configuration key.
    ///   - value: The value to set.
    public func set<V>(_ key: ConfigKey<V>, value: V) {
        lock.lock()
        globalValues[key.name] = value
        lock.unlock()
    }

    /// Sets a value for a key that applies only in the specified environment.
    /// - Parameters:
    ///   - key: The configuration key.
    ///   - value: The value to set.
    ///   - environment: The environment this value applies to.
    public func set<V>(_ key: ConfigKey<V>, value: V, for environment: SyzygyEnvironment) {
        lock.lock()
        envValues[environment, default: [:]][key.name] = value
        lock.unlock()
    }

    /// Switches the active environment.
    /// - Parameter env: The environment to switch to.
    public func switchEnvironment(to env: SyzygyEnvironment) {
        lock.lock()
        _environment = env
        lock.unlock()
    }
}
