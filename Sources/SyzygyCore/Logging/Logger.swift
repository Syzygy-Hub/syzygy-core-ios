// MARK: - Logging
// Log levels, destinations, metadata support, and multi-destination routing.

import Foundation
import SyzygyFoundation

// TODO(v1.2.0): align verbose case with Foundation — pending Foundation 1.2.0
// TODO(Foundation-v1.2.0): map CoreLogLevel.verbose to
// Foundation.LogLevel.verbose once that case is added.
// Until then, verbose dispatches as .debug.
/// Core-internal severity level that extends Foundation with `.verbose` for
/// fine-grained diagnostic output.  Not exported publicly; consumers use
/// Foundation's `LogLevel` (re-exported via the typealias below).
internal enum CoreLogLevel: Int, Sendable, Comparable, CaseIterable {
    case verbose = 0
    case debug
    case info
    case warning
    case error
    case critical

    internal static func < (lhs: CoreLogLevel, rhs: CoreLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Re-exports Foundation's `LogLevel` so Core consumers and Foundation
/// consumers share the same type and raw values, eliminating the HI-08
/// ambiguity caused by Core's previously exported 6-case enum.
public typealias LogLevel = SyzygyFoundation.LogLevel

/// A destination that receives formatted log messages with metadata.
public protocol LogDestination: Sendable {
    /// Writes a log message at the given level with associated metadata, optional timestamp, and optional error.
    ///
    /// Default implementations of `timestamp` and `error` are provided so existing conformers
    /// only need to add the new parameters if they want to handle them.
    func write(
        message: String,
        level: LogLevel,
        metadata: [String: String],
        timestamp: SyzygyFoundation.SyzygyTimestamp?,
        error: (any Error)?
    )
}

public extension LogDestination {
    /// Convenience overload — forwards to the full signature with nil timestamp and error.
    func write(message: String, level: LogLevel, metadata: [String: String]) {
        write(message: message, level: level, metadata: metadata, timestamp: nil, error: nil)
    }
}

/// Console log destination that prints to stdout.
public struct ConsoleLogDestination: LogDestination, Sendable {
    /// Creates a console log destination.
    public init() {}

    /// Writes a formatted log message to the console, including timestamp and error when present.
    public func write(
        message: String,
        level: LogLevel,
        metadata: [String: String],
        timestamp: SyzygyFoundation.SyzygyTimestamp?,
        error: (any Error)?
    ) {
        let tsString = timestamp.map { " ts=\($0.millisecondsSinceEpoch)" } ?? ""
        let metaString = metadata.isEmpty ? "" : " \(metadata)"
        var line = "[\(level)]\(tsString) \(message)\(metaString)"
        if let err = error { line += " error=\(err)" }
        print(line)
    }
}

/// Logger that routes messages to multiple destinations with minimum level filtering.
///
/// Also conforms to Foundation's `LoggerProtocol`; entries received via that
/// contract are forwarded directly through the routing pipeline using
/// Foundation's `LogLevel` (the public `LogLevel` typealias).
public final class Logger: @unchecked Sendable {
    private let lock = NSLock()
    private var destinations: [(destination: any LogDestination, minLevel: LogLevel)] = []

    /// Creates a new logger with no destinations.
    public init() {}

    /// Adds a destination that receives messages at or above the specified minimum level.
    /// - Parameters:
    ///   - dest: The log destination to add.
    ///   - minLevel: The minimum level for messages routed to this destination.
    ///     Defaults to `.debug` (the most permissive Foundation level).
    public func addDestination(_ dest: any LogDestination, minLevel: LogLevel = .debug) {
        lock.lock()
        destinations.append((destination: dest, minLevel: minLevel))
        lock.unlock()
    }

    /// Logs a message at the specified level with optional metadata.
    /// - Parameters:
    ///   - level: The severity level of the message.
    ///   - message: The log message.
    ///   - metadata: Optional key-value metadata to attach.
    ///   - timestamp: Optional timestamp for the log entry.
    ///   - error: Optional underlying error to attach.
    public func log(
        _ level: LogLevel,
        _ message: String,
        metadata: [String: String] = [:],
        timestamp: SyzygyFoundation.SyzygyTimestamp? = nil,
        error: (any Error)? = nil
    ) {
        lock.lock()
        let dests = destinations
        lock.unlock()
        for entry in dests where level >= entry.minLevel {
            entry.destination.write(
                message: message,
                level: level,
                metadata: metadata,
                timestamp: timestamp,
                error: error
            )
        }
    }
}

// MARK: - Foundation LoggerProtocol conformance

extension Logger: LoggerProtocol {
    /// Receives a Foundation `LogEntry` and routes it directly through Core's
    /// pipeline.  Because `LogLevel` is now a typealias for
    /// `SyzygyFoundation.LogLevel`, no level mapping is required.
    public func log(_ entry: SyzygyFoundation.LogEntry) {
        log(entry.level, entry.message, metadata: entry.metadata, timestamp: entry.timestamp, error: entry.error)
    }
}
