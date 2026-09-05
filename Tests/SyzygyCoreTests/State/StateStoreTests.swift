import Testing
@testable import SyzygyCore

@Suite("State Management Tests")
struct StateStoreTests {
    @Test func storeHoldsInitialState() {
        let store = StateStore(initial: 0)
        _ = store
    }
}
