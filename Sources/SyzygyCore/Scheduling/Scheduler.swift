// MARK: - Scheduling
// Debounce, throttle, delayed execution, and cancellable tasks.

import Foundation

/// A cancellable handle for a scheduled operation.
public protocol CancellableTask: Sendable {
    /// Cancels the scheduled operation.
    func cancel()
    /// Whether the task has been cancelled.
    var isCancelled: Bool { get }
}

/// A scheduler that can delay execution of actions.
public protocol SchedulerProtocol: Sendable {
    /// Schedules an action to run after a delay.
    /// - Parameters:
    ///   - delay: The duration to wait before executing.
    ///   - action: The action to execute.
    /// - Returns: A handle that can cancel the scheduled action.
    @discardableResult
    func schedule(after delay: Duration, action: @escaping @Sendable () -> Void) -> CancellableTask
}

/// Default scheduler using Swift concurrency `Task.sleep`.
public final class DefaultScheduler: SchedulerProtocol, Sendable {
    /// Creates a default scheduler.
    public init() {}

    /// Schedules an action after the specified delay.
    @discardableResult
    public func schedule(after delay: Duration, action: @escaping @Sendable () -> Void) -> CancellableTask {
        let handle = TaskHandle()
        let task = Task {
            try await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            action()
        }
        handle.setTask(task)
        return handle
    }
}

/// A cancellable wrapper around a Swift `Task`.
public final class TaskHandle: CancellableTask, @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, any Error>?
    private var _isCancelled = false

    /// Whether this task has been cancelled.
    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCancelled
    }

    init() {}

    func setTask(_ task: Task<Void, any Error>) {
        lock.lock()
        self.task = task
        if _isCancelled { task.cancel() }
        lock.unlock()
    }

    /// Cancels the underlying task.
    public func cancel() {
        lock.lock()
        _isCancelled = true
        let pendingTask = task
        lock.unlock()
        pendingTask?.cancel()
    }
}

/// Debounces rapid calls, executing only after a quiet period.
public final class Debouncer: @unchecked Sendable {
    private let delay: Duration
    private let scheduler: any SchedulerProtocol
    private let lock = NSLock()
    private var pending: CancellableTask?

    /// Creates a debouncer.
    /// - Parameters:
    ///   - delay: The quiet period duration before executing.
    ///   - scheduler: The scheduler to use (default: `DefaultScheduler`).
    public init(delay: Duration, scheduler: any SchedulerProtocol = DefaultScheduler()) {
        self.delay = delay
        self.scheduler = scheduler
    }

    /// Schedules the action, cancelling any previously pending action.
    /// - Parameter action: The action to debounce.
    public func call(_ action: @escaping @Sendable () -> Void) {
        lock.lock()
        pending?.cancel()
        let task = scheduler.schedule(after: delay, action: action)
        pending = task
        lock.unlock()
    }
}

/// Throttles rapid calls, allowing execution at most once per interval.
public final class Throttler: @unchecked Sendable {
    private let interval: Duration
    private let clock: @Sendable () -> ContinuousClock.Instant
    private let lock = NSLock()
    private var lastExecution: ContinuousClock.Instant?

    /// Creates a throttler.
    /// - Parameters:
    ///   - interval: The minimum interval between executions.
    ///   - clock: A closure returning the current instant. Defaults to `ContinuousClock.now`.
    ///            Inject a fake clock in tests to control time deterministically.
    public init(interval: Duration, clock: @Sendable @escaping () -> ContinuousClock.Instant = { ContinuousClock.now }) {
        self.interval = interval
        self.clock = clock
    }

    /// Executes the action only if enough time has passed since the last execution.
    /// - Parameter action: The action to throttle.
    public func call(_ action: @escaping @Sendable () -> Void) {
        let now = clock()
        lock.lock()
        if let last = lastExecution, now - last < interval {
            lock.unlock()
            return
        }
        lastExecution = now
        lock.unlock()
        action()
    }
}
