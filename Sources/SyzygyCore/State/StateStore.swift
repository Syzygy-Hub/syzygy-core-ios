// MARK: - State Management
// Reactive state stores, observable properties, state reducers, and selectors.

import SyzygyFoundation

/// A reactive store that holds state and notifies observers on change.
public final class StateStore<State: Sendable>: @unchecked Sendable {
    // TODO: state storage, reduce, select, observe
    public init(initial: State) {
        _ = initial
    }
}

/// Reduces the current state with an action to produce a new state.
public protocol StateReducer<State, Action> {
    associatedtype State
    associatedtype Action
    func reduce(_ state: State, action: Action) -> State
}
