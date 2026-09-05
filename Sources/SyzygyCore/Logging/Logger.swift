// MARK: - Logging
// Log levels, formatters, pipeline routing, and destinations.

import SyzygyFoundation

/// Severity level for log messages.
public enum LogLevel: Int, Sendable, Comparable {
    case debug = 0
    case info
    case warning
    case error
    case fatal

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A destination that receives formatted log messages.
public protocol LogDestination: Sendable {
    func write(_ message: String, level: LogLevel)
}

/// Console log destination that prints to stdout.
public struct ConsoleLogDestination: LogDestination {
    public init() {}
    public func write(_ message: String, level: LogLevel) {
        print("[\(level)] \(message)")
    }
}

/// Logger that routes messages through a pipeline of destinations.
public final class Logger: @unchecked Sendable {
    // TODO: destinations, formatters, pipeline routing, minimum level filtering
    public init() {}
}
