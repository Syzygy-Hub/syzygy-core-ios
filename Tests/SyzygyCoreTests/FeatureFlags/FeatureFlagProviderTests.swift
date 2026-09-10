import Testing
@testable import SyzygyCore

@Suite("Feature Flags Tests")
struct FeatureFlagProviderTests {

    @Test func defaultValueReturned() {
        let flag = FeatureFlag(key: "dark_mode", defaultValue: false, description: "Dark mode toggle")
        let provider = InMemoryFeatureFlagProvider()
        #expect(provider.value(for: flag) == false)
    }

    @Test func setValueOverridesDefault() {
        let flag = FeatureFlag(key: "limit", defaultValue: 10)
        let provider = InMemoryFeatureFlagProvider()
        provider.setValue(25, for: flag)
        #expect(provider.value(for: flag) == 25)
    }

    @Test func overrideTakesPrecedence() {
        let flag = FeatureFlag(key: "enabled", defaultValue: false)
        let provider = InMemoryFeatureFlagProvider()
        provider.setValue(false, for: flag)
        provider.setOverride(true, for: flag)
        #expect(provider.value(for: flag) == true)
    }

    @Test func clearOverrideFallsBackToBaseValue() {
        let flag = FeatureFlag(key: "count", defaultValue: 0)
        let provider = InMemoryFeatureFlagProvider()
        provider.setValue(5, for: flag)
        provider.setOverride(99, for: flag)
        #expect(provider.value(for: flag) == 99)
        provider.clearOverride(for: flag)
        #expect(provider.value(for: flag) == 5)
    }

    @Test func protocolConformance() {
        let flag = FeatureFlag(key: "x", defaultValue: "default")
        let provider: any FeatureFlagProvider = InMemoryFeatureFlagProvider()
        #expect(provider.value(for: flag) == "default")
    }
}
