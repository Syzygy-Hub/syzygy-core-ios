import Testing
@testable import SyzygyCore

@Suite("Validation Tests")
struct ValidatorTests {

    @Test func requiredValidator() {
        let validator = RequiredValidator()
        #expect(validator.validate("hello") == .valid)
        #expect(validator.validate("") != .valid)
        #expect(validator.validate("   ") != .valid)
    }

    @Test func minAndMaxLength() {
        let min = MinLengthValidator(3)
        #expect(min.validate("ab") != .valid)
        #expect(min.validate("abc") == .valid)

        let max = MaxLengthValidator(5)
        #expect(max.validate("hello") == .valid)
        #expect(max.validate("toolong") != .valid)
    }

    @Test func emailValidator() {
        let validator = EmailValidator()
        #expect(validator.validate("user@example.com") == .valid)
        #expect(validator.validate("noat") != .valid)
        #expect(validator.validate("@example.com") != .valid)
        #expect(validator.validate("user@.com") != .valid)
    }

    @Test func pipelineShortCircuit() {
        let pipeline = ValidationPipeline<String>(
            validators: [RequiredValidator(), MinLengthValidator(5)],
            mode: .shortCircuit
        )
        // Empty triggers required first; result carries a single-message list.
        if case .invalid(let msgs) = pipeline.validate("") {
            #expect(msgs == ["Value is required"])
        } else {
            Issue.record("Expected invalid")
        }
    }

    @Test func pipelineCollectAll() {
        let pipeline = ValidationPipeline<String>(
            validators: [MinLengthValidator(5), MaxLengthValidator(3)],
            mode: .collectAll
        )
        // "abcd" fails both: length 4 < 5 and 4 > 3; all messages are collected.
        if case .invalid(let msgs) = pipeline.validate("abcd") {
            #expect(msgs.count == 2)
        } else {
            Issue.record("Expected combined errors")
        }
    }
}
