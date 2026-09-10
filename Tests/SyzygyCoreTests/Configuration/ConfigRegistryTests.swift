import Testing
import SyzygyFoundation
@testable import SyzygyCore

// NOTE: Environment switched from Core's former `.development` to Foundation's
// `.debug`. Foundation's SyzygyEnvironment cases are: .debug / .staging / .production.

@Suite("Configuration Tests")
struct ConfigRegistryTests {

    @Test func returnsDefaultValue() {
        let key = ConfigKey(name: "timeout", defaultValue: 30)
        let registry = ConfigRegistry(environment: .production)
        #expect(registry.get(key) == 30)
    }

    @Test func globalValueOverridesDefault() {
        let key = ConfigKey(name: "timeout", defaultValue: 30)
        let registry = ConfigRegistry()
        registry.set(key, value: 60)
        #expect(registry.get(key) == 60)
    }

    @Test func envValueOverridesGlobal() {
        let key = ConfigKey(name: "api_url", defaultValue: "default")
        let registry = ConfigRegistry(environment: .staging)
        registry.set(key, value: "global-url")
        registry.set(key, value: "staging-url", for: .staging)
        #expect(registry.get(key) == "staging-url")
    }

    @Test func switchEnvironmentChangesResolution() {
        let key = ConfigKey(name: "debug", defaultValue: false)
        let registry = ConfigRegistry(environment: .production)
        registry.set(key, value: true, for: .debug)
        #expect(registry.get(key) == false)
        registry.switchEnvironment(to: .debug)
        #expect(registry.get(key) == true)
        #expect(registry.environment == .debug)
    }
}
