import Testing
@testable import SyzygyCore

@Suite("Configuration Tests")
struct ConfigRegistryTests {
    @Test func registryInitialisesWithEnvironment() {
        let registry = ConfigRegistry(environment: .development)
        _ = registry
    }
}
