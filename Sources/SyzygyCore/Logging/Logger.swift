// MARK: - Logging
// Log levels, destinations, metadata support, and multi-destination routing.

import Foundation
import SyzygyFoundation

/// Severity level for log messages, ordered from least to most severe.
///
/// Core extends Foundation's `LogLevel` set with `.verbose` for fine-grained
/// diagnostic output. When routing through Foundation's `LoggerProtocol`,
/// `.verbose` is mapped to `.debug`.
public enum LogLevel: Int, Sendable, Comparable, CaseIterable {
    case verbose = 0
    case debug
    case info
    case warning
    case error
    case critical

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A destination that receives formatted log messages with metadata.
public protocol LogDestination: Sendable {
    /// Writes a log message at the given level with associated metadata.
    func write(message: String, level: LogLevel, metadata: [String: String])
}

/// Console log destination that prints to stdout.
public struct ConsoleLogDestination: LogDestination, Sendable {
    /// Creates a console log destination.
    public init() {}

    /// Writes a formatted log message to the console.
    public func write(message: String, level: LogLevel, metadata: [String: String]) {
        let metaString = metadata.isEmpty ? "" : " \(metadata)"
        print("[\(level)] \(message)\(metaString)")
    }
}

/// Logger that routes messages to multiple destinations with minimum level filtering.
///
/// Also conforms to Foundation's `LoggerProtocol`; entries received via that
/// contract are translated to Core's `LogLevel` and forwarded through the
/// existing routing pipeline. Foundation's `debug` level maps to Core's `.debug`
/// (not `.verbose`).
public final class Logger: @unchecked Sendable {
    private let lock = NSLock()
    private var destinations: [(destination: any LogDestination, minLevel: LogLevel)] = []

    /// Creates a new logger with no destinations.
    public init() {}

    /// Adds a destination that receives messages at or above the specified minimum level.
    /// - Parameters:
    ///   - dest: The log destination to add.
    ///   - minLevel: The minimum level for messages routed to this destination.
    public func addDestination(_ dest: any LogDestination, minLevel: LogLevel = .verbose) {
        lock.lock()
        destinations.append((destination: dest, minLevel: minLevel))
        lock.unlock()
    }

    /// Logs a message at the specified level with optional metadata.
    /// - Parameters:
    ///   - level: The severity level of the message.
    ///   - message: The log message.
    ///   - metadata: Optional key-value metadata to attach.
    public func log(_ level: LogLevel, _ message: String, metadata: [String: String] = [:]) {
        lock.lock()
        let dests = destinations
        lock.unlock()
        for entry in dests where level >= entry.minLevel {
            entry.destination.write(message: message, level: level, metadata: metadata)
        }
    }
}

// MARK: - Foundation LoggerProtocol conformance

extension Logger: LoggerProtocol {
    /// Receives a Foundation `LogEntry` and routes it through Core's pipeline.
    ///
    /// Foundation `LogLevel` → Core `LogLevel` mapping:
    /// - `.debug`   → `.debug`   (`.verbose` is Core-only and not produced here)
    /// - `.info`    → `.info`
    /// - `.warning` → `.warning`
    /// - `.error`   → `.error`
    /// - `.critical`→ `.critical`
    public func log(_ entry: SyzygyFoundation.LogEntry) {
        let coreLevel: LogLevel
        switch entry.level {
        case .debug:    coreLevel = .debug
        case .info:     coreLevel = .info
        case .warning:  coreLevel = .warning
        case .error:    coreLevel = .error
        case .critical: coreLevel = .critical
        }
        log(coreLevel, entry.message, metadata: entry.metadata)
    }
}
