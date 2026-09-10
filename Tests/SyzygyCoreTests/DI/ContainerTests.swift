import Testing
import Foundation
@testable import SyzygyCore

/// Thread-safe accumulator for test assertions.
private final class Box<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ value: T) { _value = value }
    var value: T { lock.lock(); defer { lock.unlock() }; return _value }
    func mutate(_ block: (inout T) -> Void) { lock.lock(); block(&_value); lock.unlock() }
}

@Suite("DI Container Tests")
struct ContainerTests {

    @Test func resolveTransientCreatesNewInstances() async throws {
        let container = Container()
        await container.register(Int.self, lifetime: .transient) { _ in 42 }
        let resolved = try await container.resolve(Int.self)
        #expect(resolved == 42)
    }

    @Test func resolveSingletonReturnsSameValue() async throws {
        let container = Container()
        let count = Box(0)
        await container.register(String.self, lifetime: .singleton) { _ in
            count.mutate { $0 += 1 }
            return "instance-\(count.value)"
        }
        let first = try await container.resolve(String.self)
        let second = try await container.resolve(String.self)
        #expect(first == second)
        #expect(first == "instance-1")
    }

    @Test func resolveUnregisteredThrows() async {
        let container = Container()
        do {
            _ = try await container.resolve(Int.self)
            Issue.record("Expected notRegistered error")
        } catch let error as ContainerError {
            #expect(error == .notRegistered("Int"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func circularDependencyThrows() async {
        let container = Container()
        await container.register(Int.self, lifetime: .transient) { ctx in
            _ = try await ctx.resolve(Int.self)
            return 1
        }
        do {
            _ = try await container.resolve(Int.self)
            Issue.record("Expected circularDependency error")
        } catch let error as ContainerError {
            #expect(error == .circularDependency("Int"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func childContainerInheritsParent() async throws {
        let parent = Container()
        await parent.register(Int.self, lifetime: .singleton) { _ in 99 }
        let child = await parent.createChildContainer()
        let value = try await child.resolve(Int.self)
        #expect(value == 99)
    }
}
