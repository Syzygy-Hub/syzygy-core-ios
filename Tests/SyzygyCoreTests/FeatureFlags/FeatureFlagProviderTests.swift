import Testing
@testable import SyzygyCore

@Suite("Feature Flags Tests")
struct FeatureFlagProviderTests {
    @Test func flagHoldsDefaultValue() {
        let flag = FeatureFlag(key: "dark_mode", defaultValue: false)
        #expect(flag.defaultValue == false)
    }
}
