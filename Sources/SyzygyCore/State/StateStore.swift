// MARK: - State Management
// Reactive state stores with reducers, selectors, and AsyncStream-based observation.

import Foundation

/// Reduces the current state with an action to produce a new state.
public protocol StateReducer<State, Action> {
    associatedtype State
    associatedtype Action
    /// Produces a new state by applying the action to the current state.
    func reduce(state: State, action: Action) -> State
}

/// A reactive store that holds immutable state, dispatches actions through a reducer,
/// and provides observation via `AsyncStream`.
public final class StateStore<State: Sendable, Action: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _state: State
    private let reducer: @Sendable (State, Action) -> State
    private var continuations: [UUID: AsyncStream<State>.Continuation] = [:]

    /// The current state snapshot.
    public var currentState: State {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    /// Creates a store with an initial state and a reducer function.
    /// - Parameters:
    ///   - initial: The initial state value.
    ///   - reducer: A pure function that produces new state from state + action.
    public init(initial: State, reducer: @Sendable @escaping (State, Action) -> State) {
        self._state = initial
        self.reducer = reducer
    }

    /// Creates a store using a `StateReducer` conformance.
    /// - Parameters:
    ///   - initial: The initial state value.
    ///   - reducer: A `StateReducer` instance.
    public convenience init<R: StateReducer>(initial: State, reducer: R) where R.State == State, R.Action == Action, R: Sendable {
        self.init(initial: initial) { state, action in
            reducer.reduce(state: state, action: action)
        }
    }

    /// Dispatches an action through the reducer, updating the state and notifying observers.
    /// - Parameter action: The action to dispatch.
    public func dispatch(_ action: Action) {
        lock.lock()
        _state = reducer(_state, action)
        let newState = _state
        let conts = continuations
        lock.unlock()
        for (_, cont) in conts {
            cont.yield(newState)
        }
    }

    /// Returns an `AsyncStream` that emits the current state immediately, then every subsequent state change.
    ///
    /// The continuation is registered **inside** the lock before the initial state is yielded,
    /// so any concurrent `dispatch(_:)` between registering and yielding is not lost — it will
    /// either be captured in the initial yield or arrive immediately after via the continuation.
    /// - Returns: An `AsyncStream` of state values.
    public func observe() -> AsyncStream<State> {
        let id = UUID()
        return AsyncStream { continuation in
            self.lock.lock()
            self.continuations[id] = continuation
            let snapshot = self._state
            self.lock.unlock()
            continuation.yield(snapshot)
            continuation.onTermination = { @Sendable _ in
                self.lock.lock()
                self.continuations.removeValue(forKey: id)
                self.lock.unlock()
            }
        }
    }

    /// Returns an `AsyncStream` that emits derived values from state, de-duplicating consecutive equal values.
    /// - Parameter selector: A function that extracts a derived value from the state.
    /// - Returns: An `AsyncStream` of the selected values, only emitting when the value changes.
    public func select<T: Equatable & Sendable>(_ selector: @Sendable @escaping (State) -> T) -> AsyncStream<T> {
        let source = observe()
        return AsyncStream { continuation in
            let task = Task {
                var last: T?
                for await state in source {
                    let value = selector(state)
                    if value != last {
                        last = value
                        continuation.yield(value)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
