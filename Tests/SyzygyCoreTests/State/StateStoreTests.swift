import Testing
import Foundation
@testable import SyzygyCore

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

    @Test func observeDoesNotMissDispatchConcurrentWithSubscription() async throws {
        // Verifies the FIX 2 TOCTOU fix: a dispatch that races with a new observe() call
        // must not be silently dropped. The continuation is registered inside the lock
        // before the initial state snapshot is taken, so the observer always sees either
        // the state-at-subscription or the concurrent update (or both).
        let store = StateStore<Int, Int>(initial: 0) { _, action in action }
        let seen = Box<Set<Int>>([])
        let ready = Box(false)

        let observeTask = Task {
            let stream = store.observe()
            ready.mutate { $0 = true }
            for await value in stream {
                seen.mutate { $0.insert(value) }
                if seen.value.count >= 2 { break }
            }
        }

        // Wait until the observer task has started, then race a dispatch against it.
        while !ready.value { await Task.yield() }
        store.dispatch(99)

        try await Task.sleep(for: .milliseconds(100))
        observeTask.cancel()
        await observeTask.value

        // The observer must have received at least the initial state (0) and the dispatched value (99).
        #expect(seen.value.contains(0))
        #expect(seen.value.contains(99))
    }

    // MARK: - ITEM 6: Concurrent dispatch stress test

    @Test func concurrentDispatchesDoNotLoseUpdates() {
        let store = StateStore<Int, Int>(initial: 0) { state, action in state + action }
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "stress", attributes: .concurrent)
        for _ in 0..<100 {
            group.enter()
            queue.async {
                store.dispatch(1)
                group.leave()
            }
        }
        group.wait()
        #expect(store.currentState == 100)
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
