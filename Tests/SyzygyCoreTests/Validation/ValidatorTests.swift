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

    @Test func pipelineCollectAllBothPass() {
        // MinLength(2) + MaxLength(10): "hello" (5 chars) passes both.
        let pipeline = ValidationPipeline<String>(
            validators: [MinLengthValidator(2), MaxLengthValidator(10)],
            mode: .collectAll
        )
        #expect(pipeline.validate("hello") == .valid)
    }

    @Test func pipelineCollectAllSecondFails() {
        // MinLength(2) + MaxLength(4): "hello" (5 chars) passes min, fails max → 1 error.
        let pipeline = ValidationPipeline<String>(
            validators: [MinLengthValidator(2), MaxLengthValidator(4)],
            mode: .collectAll
        )
        if case .invalid(let msgs) = pipeline.validate("hello") {
            #expect(msgs.count == 1)
        } else {
            Issue.record("Expected 1 invalid message")
        }
    }

    // MARK: - ITEM 9: EmailValidator strict mode

    @Test func strictModeAcceptsValidEmail() {
        let validator = EmailValidator(strict: true)
        #expect(validator.validate("user@example.com") == .valid)
    }

    @Test func strictModeRejectsLongLocalPart() {
        let validator = EmailValidator(strict: true)
        let longLocal = String(repeating: "a", count: 65)
        #expect(validator.validate("\(longLocal)@example.com") != .valid)
    }

    @Test func strictModeRejectsTotalOver255() {
        let validator = EmailValidator(strict: true)
        // local(64) + "@" + domain needs to exceed 255 total
        let local = String(repeating: "a", count: 64)
        let domain = String(repeating: "b", count: 190) + ".com"
        let email = "\(local)@\(domain)"
        #expect(email.count > 255)
        #expect(validator.validate(email) != .valid)
    }

    @Test func strictModeRejectsConsecutiveDots() {
        let validator = EmailValidator(strict: true)
        #expect(validator.validate("user..name@example.com") != .valid)
    }

    @Test func pipelineCollectAllBothFail() {
        // MinLength(10) + MaxLength(100): "hello" (5 chars) fails min, passes max — wait, MaxLength(100)
        // passes for "hello". So use MinLength(10) + MaxLength(3) to get 2 failures:
        // "hello" (5) fails both — length 5 < 10 and 5 > 3.
        let pipeline = ValidationPipeline<String>(
            validators: [MinLengthValidator(10), MaxLengthValidator(3)],
            mode: .collectAll
        )
        if case .invalid(let msgs) = pipeline.validate("hello") {
            #expect(msgs.count == 2)
        } else {
            Issue.record("Expected 2 invalid messages")
        }
    }
}
