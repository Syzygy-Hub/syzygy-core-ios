import Testing
@testable import SyzygyCore

@Suite("Logging Tests")
struct LoggerTests {
    @Test func logLevelOrdering() {
        #expect(LogLevel.debug < LogLevel.error)
    }

    @Test func consoleDestinationWrites() {
        let dest = ConsoleLogDestination()
        dest.write("test", level: .info)
    }
}
