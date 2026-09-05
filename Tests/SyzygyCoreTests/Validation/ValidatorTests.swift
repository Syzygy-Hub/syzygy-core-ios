import Testing
@testable import SyzygyCore

@Suite("Validation Tests")
struct ValidatorTests {
    @Test func validResultIsValid() {
        let result = ValidationResult.valid
        if case .valid = result {
            // pass
        } else {
            Issue.record("Expected .valid")
        }
    }
}
