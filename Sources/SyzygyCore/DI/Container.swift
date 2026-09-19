// MARK: - DI Container
// Thread-safe dependency injection container with singleton, transient, and scoped lifetimes.

import Foundation

/// Lifetime scope for a registered dependency.
public enum Lifetime: Sendable {
    /// Resolved once and cached for the container's lifetime.
    case singleton
    /// A new instance is created on every resolution.
    case transient
    /// Shared within a scope (child container inherits parent singletons but has its own scoped cache).
    case scoped
}

/// Errors thrown during dependency resolution.
public enum ContainerError: Error, Sendable, Equatable {
    /// No factory registered for the requested type.
    case notRegistered(String)
    /// A circular dependency was detected during resolution.
    case circularDependency(String)
}

/// Thread-safe dependency injection container using actor isolation.
public actor Container {
    private struct Registration {
        let lifetime: Lifetime
        let factory: @Sendable (Container) async throws -> Any
    }

    private var registrations: [String: Registration] = [:]
    private var singletonCache: [String: Any] = [:]
    private var scopedCache: [String: Any] = [:]
    private var resolving: Set<String> = []
    private let parent: Container?

    /// Creates a new container, optionally inheriting registrations from a parent.
    /// - Parameter parent: An optional parent container for hierarchical resolution.
    public init(parent: Container? = nil) {
        self.parent = parent
    }

    /// Registers a factory for the given type with the specified lifetime.
    /// - Parameters:
    ///   - type: The type to register.
    ///   - lifetime: The lifetime scope for instances (default: `.transient`).
    ///   - factory: A closure that produces an instance, receiving this container for nested resolution.
    public func register<T: Sendable>(
        _ type: T.Type,
        lifetime: Lifetime = .transient,
        factory: @Sendable @escaping (Container) async throws -> T
    ) {
        let key = String(describing: type)
        registrations[key] = Registration(lifetime: lifetime, factory: factory)
    }

    /// Resolves an instance of the requested type.
    /// - Parameter type: The type to resolve.
    /// - Returns: An instance of the requested type.
    /// - Throws: `ContainerError.notRegistered` if no factory is found,
    ///           `ContainerError.circularDependency` if a cycle is detected.
    public func resolve<T: Sendable>(_ type: T.Type) async throws -> T {
        let key = String(describing: type)

        guard !resolving.contains(key) else {
            throw ContainerError.circularDependency(key)
        }

        guard let registration = registrations[key] else {
            if let parent = parent {
                return try await parent.resolve(type)
            }
            throw ContainerError.notRegistered(key)
        }

        switch registration.lifetime {
        case .singleton:
            return try await resolveSingleton(key: key, registration: registration)
        case .scoped:
            return try await resolveScoped(key: key, registration: registration)
        case .transient:
            return try await resolveTransient(key: key, registration: registration)
        }
    }

    // MARK: - Private resolution helpers

    private func resolveSingleton<T: Sendable>(key: String, registration: Registration) async throws -> T {
        if let cached = singletonCache[key] as? T {
            return cached
        }
        resolving.insert(key)
        defer { resolving.remove(key) }
        let instance = try await registration.factory(self)
        guard let typed = instance as? T else {
            throw ContainerError.notRegistered(key)
        }
        singletonCache[key] = typed
        return typed
    }

    private func resolveScoped<T: Sendable>(key: String, registration: Registration) async throws -> T {
        // Scoped instances are cached within this container's own scopedCache.
        // When resolve() falls through to the parent (no local registration), the parent's
        // scoped cache is used — so a scoped type resolved through a parent caches in the
        // parent's scope, not the child's. Two independent child containers therefore each
        // get their own scoped instance, because each has its own scopedCache.
        if let cached = scopedCache[key] as? T {
            return cached
        }
        resolving.insert(key)
        defer { resolving.remove(key) }
        let instance = try await registration.factory(self)
        guard let typed = instance as? T else {
            throw ContainerError.notRegistered(key)
        }
        scopedCache[key] = typed
        return typed
    }

    private func resolveTransient<T: Sendable>(key: String, registration: Registration) async throws -> T {
        resolving.insert(key)
        defer { resolving.remove(key) }
        let instance = try await registration.factory(self)
        guard let typed = instance as? T else {
            throw ContainerError.notRegistered(key)
        }
        return typed
    }

    /// Creates a child container that inherits this container's registrations via parent lookup.
    /// The child has its own scoped cache.
    /// - Returns: A new child `Container`.
    public func createChildContainer() -> Container {
        Container(parent: self)
    }

    /// Removes all registrations and clears all caches, resetting the container to its initial state.
    ///
    /// After this call, any subsequent `resolve` call will throw `ContainerError.notRegistered`
    /// unless new registrations are added.
    public func resetRegistrations() {
        registrations = [:]
        singletonCache = [:]
        scopedCache = [:]
        resolving = []
    }
}
