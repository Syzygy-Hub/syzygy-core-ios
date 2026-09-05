// MARK: - Feature Flags
// Evaluation rules, flag definitions, local overrides, and A/B variant selection.

import SyzygyFoundation

/// Defines a feature flag with a key and default value.
public struct FeatureFlag<Value: Sendable>: Sendable {
    public let key: String
    public let defaultValue: Value
    public init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

/// Provides feature flag evaluation with local overrides and variant selection.
public final class FeatureFlagProvider: @unchecked Sendable {
    // TODO: evaluation rules, override storage, A/B variant selection
    public init() {}
}
