import Testing
@testable import SyzygyCore

@Suite("Event Bus Tests")
struct EventBusTests {
    @Test func busInitialises() {
        let bus = EventBus()
        _ = bus
    }
}
