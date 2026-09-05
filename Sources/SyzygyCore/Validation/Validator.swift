// MARK: - Validation
// Composable field validators, rule chaining, form-level validation pipeline, built-in rules.

import SyzygyFoundation

/// Result of a single validation check.
public enum ValidationResult: Sendable {
    case valid
    case invalid(String)
}

/// A composable validator for a single field value.
public protocol FieldValidator<Value>: Sendable {
    associatedtype Value
    func validate(_ value: Value) -> ValidationResult
}

/// Chains multiple validators into a pipeline.
public struct ValidationPipeline<Value>: FieldValidator {
    // TODO: rule chaining, short-circuit / collect-all modes
    public init(validators: [any FieldValidator<Value>]) {
        _ = validators
    }
    public func validate(_ value: Value) -> ValidationResult { .valid }
}
