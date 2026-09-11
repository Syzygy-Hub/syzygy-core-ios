import Testing
import Foundation
@testable import SyzygyCore

@Suite("Scheduling Tests")
struct SchedulerTests {

    @Test func defaultSchedulerExecutesAfterDelay() async throws {
        let scheduler = DefaultScheduler()
        let executed = Box(false)
        scheduler.schedule(after: .milliseconds(50)) { executed.mutate { $0 = true } }
        try await Task.sleep(for: .milliseconds(200))
        #expect(executed.value)
    }

    @Test func cancelPreventsExecution() async throws {
        let scheduler = DefaultScheduler()
        let executed = Box(false)
        let task = scheduler.schedule(after: .milliseconds(100)) { executed.mutate { $0 = true } }
        task.cancel()
        #expect(task.isCancelled)
        try await Task.sleep(for: .milliseconds(250))
        #expect(!executed.value)
    }

    @Test func debouncerOnlyExecutesLastCall() async throws {
        let debouncer = Debouncer(delay: .milliseconds(50))
        let values = Box<[Int]>([])
        debouncer.call { values.mutate { $0.append(1) } }
        debouncer.call { values.mutate { $0.append(2) } }
        debouncer.call { values.mutate { $0.append(3) } }
        try await Task.sleep(for: .milliseconds(200))
        #expect(values.value == [3])
    }

    @Test func throttlerLimitsRateWithFakeClock() {
        // Uses injected fake clock so the test is deterministic and instant.
        let fakeNow = Box(ContinuousClock.now)
        let throttler = Throttler(interval: .seconds(10), clock: { fakeNow.value })
        let count = Box(0)
        throttler.call { count.mutate { $0 += 1 } }  // allowed — first call
        throttler.call { count.mutate { $0 += 1 } }  // suppressed — within interval
        throttler.call { count.mutate { $0 += 1 } }  // suppressed — within interval
        #expect(count.value == 1)
    }

    @Test func throttlerAllowsCallAfterCooldown() {
        let fakeNow = Box(ContinuousClock.now)
        let throttler = Throttler(interval: .seconds(10), clock: { fakeNow.value })
        let count = Box(0)
        throttler.call { count.mutate { $0 += 1 } }  // allowed — first call
        throttler.call { count.mutate { $0 += 1 } }  // suppressed — within interval
        #expect(count.value == 1)
        // Advance fake clock past the interval.
        fakeNow.mutate { $0 = $0.advanced(by: .seconds(11)) }
        throttler.call { count.mutate { $0 += 1 } }  // allowed — past cooldown
        #expect(count.value == 2)
    }
}
