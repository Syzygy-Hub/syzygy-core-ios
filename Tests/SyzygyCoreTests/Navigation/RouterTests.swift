import Testing
@testable import SyzygyCore

@Suite("Navigation Tests")
struct RouterTests {
    @Test func routerInitialises() {
        let router = Router()
        _ = router
    }
}
