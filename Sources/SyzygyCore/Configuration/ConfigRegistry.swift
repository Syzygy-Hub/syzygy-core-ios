// MARK: - Configuration
// In-memory config registry, environment-based switching, and typed config access.

import SyzygyFoundation

/// Environment identifier for configuration switching.
public enum Environment: String, Sendable {
    case development
    case staging
    case production
}

/// In-memory configuration registry with typed access and environment switching.
public final class ConfigRegistry: @unchecked Sendable {
    // TODO: key-value storage, environment-based overlays, typed getters
    public init(environment: Environment = .production) {
        _ = environment
    }
}
