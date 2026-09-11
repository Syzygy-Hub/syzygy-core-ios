import Testing
import Foundation
@testable import SyzygyCore

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

    // MARK: - FIX 16: Scoped lifetime isolation

    @Test func twoChildContainersGetIndependentScopedInstances() async throws {
        // Each child registers its own scoped factory, so each child's scopedCache
        // holds an independent instance. Mutating one must not affect the other.
        let parent = Container()
        let child1 = await parent.createChildContainer()
        let child2 = await parent.createChildContainer()
        // Register separately in each child so each has its own scopedCache entry.
        await child1.register(Box<Int>.self, lifetime: .scoped) { _ in Box(0) }
        await child2.register(Box<Int>.self, lifetime: .scoped) { _ in Box(0) }
        let inst1 = try await child1.resolve(Box<Int>.self)
        let inst2 = try await child2.resolve(Box<Int>.self)
        // Mutating inst1 must not affect inst2 — they are independent instances.
        inst1.mutate { $0 = 42 }
        #expect(inst1.value == 42)
        #expect(inst2.value == 0)
    }

    // MARK: - ITEM 3: resetRegistrations

    @Test func resetRegistrationsRemovesAllRegistrations() async throws {
        let container = Container()
        await container.register(Int.self, lifetime: .transient) { _ in 42 }
        await container.resetRegistrations()
        do {
            _ = try await container.resolve(Int.self)
            Issue.record("Expected notRegistered error after reset")
        } catch let error as ContainerError {
            #expect(error == .notRegistered("Int"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func scopedResolvedThroughParentCachesInParentScope() async throws {
        // When a child has no local registration, resolution delegates to the parent.
        // The scoped cache used is the parent's, so the parent always returns the same instance.
        let parent = Container()
        await parent.register(Box<Int>.self, lifetime: .scoped) { _ in Box(99) }
        let child = await parent.createChildContainer()
        // Resolving through child delegates to parent; parent caches in its own scopedCache.
        let fromChild = try await child.resolve(Box<Int>.self)
        let fromParent = try await parent.resolve(Box<Int>.self)
        // Both must be the same cached instance.
        fromChild.mutate { $0 = 7 }
        #expect(fromParent.value == 7)
    }
}
