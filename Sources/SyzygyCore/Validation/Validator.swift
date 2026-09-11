// MARK: - Validation
// Composable field validators, rule chaining, form-level validation pipeline, built-in rules.

import Foundation
import SyzygyFoundation

// ValidationResult is provided by SyzygyFoundation:
//   public enum ValidationResult: Equatable, Sendable {
//       case valid
//       case invalid(messages: [String])
//   }

/// A composable validator for a single field value.
///
/// Inherits from Foundation's `ValidationRule` via the default generic-method
/// implementation provided in the extension below.
public protocol FieldValidator<Value>: ValidationRule {
    associatedtype Value
    /// Validates the given value, returning a Foundation `ValidationResult`.
    func validate(_ value: Value) -> ValidationResult
}

extension FieldValidator {
    /// Satisfies `ValidationRule.validate<T>(_:)` by attempting a typed cast.
    /// Returns `.invalid(messages:)` if the value cannot be cast to `Value`.
    public func validate<T>(_ value: T) -> ValidationResult {
        guard let typed = value as? Value else {
            return .invalid(messages: ["Type mismatch: expected \(Value.self), got \(T.self)"])
        }
        return validate(typed)
    }
}

/// Validation mode controlling how a pipeline reports errors.
public enum ValidationMode: Sendable {
    /// Stop at the first failure.
    case shortCircuit
    /// Collect all failures.
    case collectAll
}

/// Validates that a string is non-empty.
public struct RequiredValidator: FieldValidator, Sendable {
    private let message: String
    /// Creates a required validator with a custom message.
    public init(message: String = "Value is required") { self.message = message }
    public func validate(_ value: String) -> ValidationResult {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .invalid(messages: [message])
            : .valid
    }
}

/// Validates that a string meets a minimum length.
public struct MinLengthValidator: FieldValidator, Sendable {
    private let min: Int
    private let message: String
    /// Creates a min-length validator.
    public init(_ min: Int, message: String? = nil) {
        self.min = min
        self.message = message ?? "Must be at least \(min) characters"
    }
    public func validate(_ value: String) -> ValidationResult {
        value.count >= min ? .valid : .invalid(messages: [message])
    }
}

/// Validates that a string does not exceed a maximum length.
public struct MaxLengthValidator: FieldValidator, Sendable {
    private let max: Int
    private let message: String
    /// Creates a max-length validator.
    public init(_ max: Int, message: String? = nil) {
        self.max = max
        self.message = message ?? "Must be at most \(max) characters"
    }
    public func validate(_ value: String) -> ValidationResult {
        value.count <= max ? .valid : .invalid(messages: [message])
    }
}

/// Validates that a string looks like an email address.
///
/// When `strict` is `false` (the default), uses a well-formed heuristic pattern. Not RFC 5321 compliant.
/// When `strict` is `true`, additionally enforces RFC 5321 rules:
/// - Local part (before `@`) ≤ 64 characters
/// - Total length ≤ 255 characters
/// - No consecutive dots (`..`) anywhere in the address
/// - Local part cannot start or end with a dot
public struct EmailValidator: FieldValidator, Sendable {
    private let message: String
    private let strict: Bool
    /// Creates an email validator.
    /// - Parameters:
    ///   - strict: When `true`, applies RFC 5321 strict validation rules (default: `false`).
    ///   - message: The error message returned on failure.
    public init(strict: Bool = false, message: String = "Invalid email address") {
        self.strict = strict
        self.message = message
    }
    public func validate(_ value: String) -> ValidationResult {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains("."),
              !parts[1].hasPrefix("."),
              !parts[1].hasSuffix(".") else {
            return .invalid(messages: [message])
        }
        if strict {
            let local = String(parts[0])
            // Local part max 64 characters
            guard local.count <= 64 else { return .invalid(messages: [message]) }
            // Total length max 255 characters
            guard value.count <= 255 else { return .invalid(messages: [message]) }
            // No consecutive dots anywhere
            guard !value.contains("..") else { return .invalid(messages: [message]) }
            // Local part cannot start or end with a dot
            guard !local.hasPrefix("."), !local.hasSuffix(".") else { return .invalid(messages: [message]) }
        }
        return .valid
    }
}

/// Validates a string against a regular expression pattern.
public struct RegexValidator: FieldValidator, Sendable {
    private let pattern: String
    private let message: String
    /// Creates a regex validator.
    public init(pattern: String, message: String = "Invalid format") {
        self.pattern = pattern
        self.message = message
    }
    public func validate(_ value: String) -> ValidationResult {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("RegexValidator: invalid pattern '\(pattern)': \(error)")
        }
        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range) != nil
            ? .valid
            : .invalid(messages: [message])
    }
}

/// Chains multiple validators into a pipeline with configurable error collection mode.
public struct ValidationPipeline<Value>: FieldValidator, Sendable {
    private let validators: [any FieldValidator<Value>]
    private let mode: ValidationMode

    /// Creates a validation pipeline.
    /// - Parameters:
    ///   - validators: The ordered list of validators to apply.
    ///   - mode: How to handle multiple failures (default: `.shortCircuit`).
    public init(validators: [any FieldValidator<Value>], mode: ValidationMode = .shortCircuit) {
        self.validators = validators
        self.mode = mode
    }

    /// Runs all validators against the value according to the configured mode.
    ///
    /// - **shortCircuit**: returns the first `invalid` result as-is (its `messages` array intact).
    /// - **collectAll**: accumulates every failure message across all validators into a
    ///   single `invalid(messages:)` with the full list.
    public func validate(_ value: Value) -> ValidationResult {
        var accumulated: [String] = []
        for validator in validators {
            let result = validator.validate(value)
            if case .invalid(let msgs) = result {
                if mode == .shortCircuit {
                    return .invalid(messages: msgs)
                }
                accumulated.append(contentsOf: msgs)
            }
        }
        return accumulated.isEmpty ? .valid : .invalid(messages: accumulated)
    }
}
