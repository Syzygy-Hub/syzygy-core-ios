import Testing
@testable import SyzygyCore

@Suite("Scheduling Tests")
struct SchedulerTests {
    @Test func schedulerInitialises() {
        let scheduler = Scheduler()
        _ = scheduler
    }
}
