import Testing
import Foundation
import SyzygyFoundation
@testable import SyzygyCore

@Suite("Logging Tests")
struct LoggerTests {

    struct CapturedEntry: Sendable {
        let message: String
        let level: SyzygyCore.LogLevel
        let metadata: [String: String]
        let timestamp: SyzygyFoundation.SyzygyTimestamp?
        let error: (any Error)?
    }

    final class SpyDestination: LogDestination, @unchecked Sendable {
        var messages: [(String, SyzygyCore.LogLevel, [String: String])] = []
        var entries: [CapturedEntry] = []
        func write(message: String, level: SyzygyCore.LogLevel, metadata: [String: String], timestamp: SyzygyFoundation.SyzygyTimestamp?, error: (any Error)?) {
            messages.append((message, level, metadata))
            entries.append(CapturedEntry(message: message, level: level, metadata: metadata, timestamp: timestamp, error: error))
        }
    }

    @Test func logLevelOrdering() {
        #expect(SyzygyCore.LogLevel.verbose < SyzygyCore.LogLevel.debug)
        #expect(SyzygyCore.LogLevel.debug < SyzygyCore.LogLevel.info)
        #expect(SyzygyCore.LogLevel.info < SyzygyCore.LogLevel.warning)
        #expect(SyzygyCore.LogLevel.warning < SyzygyCore.LogLevel.error)
        #expect(SyzygyCore.LogLevel.error < SyzygyCore.LogLevel.critical)
    }

    @Test func loggerRoutesToDestination() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        logger.log(.info, "hello", metadata: ["key": "val"])
        #expect(spy.messages.count == 1)
        #expect(spy.messages[0].0 == "hello")
        #expect(spy.messages[0].2 == ["key": "val"])
    }

    @Test func minLevelFilters() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy, minLevel: .warning)
        logger.log(.debug, "should be filtered")
        logger.log(.warning, "should pass")
        logger.log(.critical, "also passes")
        #expect(spy.messages.count == 2)
    }

    @Test func multipleDestinations() {
        let spy1 = SpyDestination()
        let spy2 = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy1, minLevel: .verbose)
        logger.addDestination(spy2, minLevel: .error)
        logger.log(.info, "info msg")
        #expect(spy1.messages.count == 1)
        #expect(spy2.messages.isEmpty)
    }

    // MARK: - FIX 8: Foundation LogEntry bridge tests

    @Test func foundationDebugMapsToDebug() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let entry = SyzygyFoundation.LogEntry(level: .debug, message: "dbg", timestamp: .now())
        logger.log(entry)
        #expect(spy.entries.count == 1)
        #expect(spy.entries[0].level == SyzygyCore.LogLevel.debug)
    }

    @Test func foundationInfoMapsToInfo() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let entry = SyzygyFoundation.LogEntry(level: .info, message: "inf", timestamp: .now())
        logger.log(entry)
        #expect(spy.entries[0].level == SyzygyCore.LogLevel.info)
    }

    @Test func foundationWarningMapsToWarning() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let entry = SyzygyFoundation.LogEntry(level: .warning, message: "wrn", timestamp: .now())
        logger.log(entry)
        #expect(spy.entries[0].level == SyzygyCore.LogLevel.warning)
    }

    @Test func foundationErrorMapsToError() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let entry = SyzygyFoundation.LogEntry(level: .error, message: "err", timestamp: .now())
        logger.log(entry)
        #expect(spy.entries[0].level == SyzygyCore.LogLevel.error)
    }

    @Test func foundationCriticalMapsToCritical() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let entry = SyzygyFoundation.LogEntry(level: .critical, message: "crit", timestamp: .now())
        logger.log(entry)
        #expect(spy.entries[0].level == SyzygyCore.LogLevel.critical)
    }

    @Test func foundationMetadataIsForwarded() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let entry = SyzygyFoundation.LogEntry(level: .info, message: "meta-test", timestamp: .now(), metadata: ["key": "value"])
        logger.log(entry)
        #expect(spy.entries[0].metadata == ["key": "value"])
    }

    @Test func foundationTimestampIsForwarded() {
        let spy = SpyDestination()
        let logger = Logger()
        logger.addDestination(spy)
        let ts = SyzygyFoundation.SyzygyTimestamp(millisecondsSinceEpoch: 1_000_000)
        let entry = SyzygyFoundation.LogEntry(level: .info, message: "ts-test", timestamp: ts)
        logger.log(entry)
        #expect(spy.entries[0].timestamp?.millisecondsSinceEpoch == 1_000_000)
    }
}
