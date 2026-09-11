import Foundation

/// Thread-safe mutable value wrapper for use in test assertions across concurrent contexts.
final class Box<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ value: T) { _value = value }
    var value: T { lock.lock(); defer { lock.unlock() }; return _value }
    func mutate(_ block: (inout T) -> Void) { lock.lock(); block(&_value); lock.unlock() }
}
