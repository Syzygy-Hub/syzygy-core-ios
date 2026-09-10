import Testing
@testable import SyzygyCore

@Suite("Logging Tests")
struct LoggerTests {

    final class SpyDestination: LogDestination, @unchecked Sendable {
        var messages: [(String, LogLevel, [String: String])] = []
        func write(message: String, level: LogLevel, metadata: [String: String]) {
            messages.append((message, level, metadata))
        }
    }

    @Test func logLevelOrdering() {
        #expect(LogLevel.verbose < LogLevel.debug)
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(LogLevel.error < LogLevel.critical)
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
}
