import Testing
@testable import SyzygyCore

@Suite("DI Container Tests")
struct ContainerTests {
    @Test func containerInitialises() {
        let container = Container()
        _ = container
    }
}
