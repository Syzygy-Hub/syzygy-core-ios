import Testing
import Foundation
@testable import SyzygyCore

private final class Box<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ value: T) { _value = value }
    var value: T { lock.lock(); defer { lock.unlock() }; return _value }
    func mutate(_ block: (inout T) -> Void) { lock.lock(); block(&_value); lock.unlock() }
}

@Suite("State Management Tests")
struct StateStoreTests {

    @Test func storeHoldsInitialState() {
        let store = StateStore<Int, Int>(initial: 10) { state, action in state + action }
        #expect(store.currentState == 10)
    }

    @Test func dispatchUpdatesState() {
        let store = StateStore<Int, Int>(initial: 0) { state, action in state + action }
        store.dispatch(5)
        store.dispatch(3)
        #expect(store.currentState == 8)
    }

    @Test func observeEmitsCurrentAndSubsequentStates() async throws {
        let store = StateStore<Int, Int>(initial: 0) { state, action in state + action }
        let stream = store.observe()
        let collected = Box<[Int]>([])
        let task = Task {
            for await value in stream {
                collected.mutate { $0.append(value) }
                if collected.value.count >= 3 { break }
            }
        }
        try await Task.sleep(for: .milliseconds(50))
        store.dispatch(1)
        store.dispatch(2)
        await task.value
        #expect(collected.value == [0, 1, 3])
    }

    @Test func selectDeduplicatesValues() async throws {
        let store = StateStore<Int, Int>(initial: 0) { _, action in action }
        let stream = store.select { $0 / 10 }
        let collected = Box<[Int]>([])
        let task = Task {
            for await value in stream {
                collected.mutate { $0.append(value) }
                if collected.value.count >= 2 { break }
            }
        }
        try await Task.sleep(for: .milliseconds(50))
        store.dispatch(5)
        store.dispatch(15)
        await task.value
        #expect(collected.value == [0, 1])
    }

    @Test func reducerProtocolIntegration() {
        struct Counter: StateReducer, Sendable {
            func reduce(state: Int, action: String) -> Int {
                action == "inc" ? state + 1 : state
            }
        }
        let store = StateStore(initial: 0, reducer: Counter())
        store.dispatch("inc")
        store.dispatch("noop")
        store.dispatch("inc")
        #expect(store.currentState == 2)
    }
}
