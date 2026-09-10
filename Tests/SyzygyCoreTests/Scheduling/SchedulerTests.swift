import Testing
import Foundation
@testable import SyzygyCore

/// Thread-safe accumulator for test assertions.
private final class Box<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ value: T) { _value = value }
    var value: T { lock.lock(); defer { lock.unlock() }; return _value }
    func mutate(_ block: (inout T) -> Void) { lock.lock(); block(&_value); lock.unlock() }
}

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

    @Test func throttlerLimitsRate() {
        let throttler = Throttler(interval: .seconds(10))
        let count = Box(0)
        throttler.call { count.mutate { $0 += 1 } }
        throttler.call { count.mutate { $0 += 1 } }
        throttler.call { count.mutate { $0 += 1 } }
        #expect(count.value == 1)
    }
}
