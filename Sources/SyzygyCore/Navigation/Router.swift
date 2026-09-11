// MARK: - Navigation
// Route definitions, deep link URL parsing, navigation stack model, and route guards.

import Foundation

/// A navigable route definition with a path and parameters.
public protocol Route: Sendable {
    /// The path segment identifying this route.
    var path: String { get }
    /// Parameters associated with this route.
    var parameters: [String: String] { get }
}

/// A guard that can allow or block navigation to a route.
public protocol RouteGuard: Sendable {
    /// Returns `true` if navigation to the route should be allowed.
    func canNavigate(to route: any Route) -> Bool
}

/// Manages a navigation stack and applies route guards before navigation.
///
/// All mutations to `stack` and `guards` are protected by `lock`, providing
/// full thread safety. `@unchecked Sendable` is justified by that lock coverage.
public final class Router: @unchecked Sendable {
    private let lock = NSLock()
    private var stack: [any Route] = []
    private var guards: [any RouteGuard] = []

    /// The currently active route (top of the stack), or `nil` if the stack is empty.
    public var currentRoute: (any Route)? {
        lock.lock(); defer { lock.unlock() }
        return stack.last
    }

    /// The number of routes on the navigation stack.
    public var stackDepth: Int {
        lock.lock(); defer { lock.unlock() }
        return stack.count
    }

    /// Creates an empty router.
    public init() {}

    /// Adds a route guard that is consulted before every navigation.
    /// - Parameter guard: The guard to add.
    public func addGuard(_ guard: any RouteGuard) {
        lock.lock(); defer { lock.unlock() }
        guards.append(`guard`)
    }

    /// Pushes a route onto the stack if all guards allow it.
    /// - Parameter route: The route to push.
    /// - Returns: `true` if the route was pushed, `false` if a guard blocked it.
    @discardableResult
    public func push(_ route: any Route) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard canPassLocked(route) else { return false }
        stack.append(route)
        return true
    }

    /// Pops the top route from the stack.
    /// - Returns: The removed route, or `nil` if the stack was empty.
    @discardableResult
    public func pop() -> (any Route)? {
        lock.lock(); defer { lock.unlock() }
        return stack.isEmpty ? nil : stack.removeLast()
    }

    /// Pops all routes except the root.
    public func popToRoot() {
        lock.lock(); defer { lock.unlock() }
        guard stack.count > 1 else { return }
        stack = [stack[0]]
    }

    /// Replaces the top route with a new one if all guards allow it.
    /// - Parameter route: The replacement route.
    /// - Returns: `true` if the replacement succeeded, `false` if a guard blocked it.
    @discardableResult
    public func replace(with route: any Route) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard canPassLocked(route) else { return false }
        if !stack.isEmpty { stack.removeLast() }
        stack.append(route)
        return true
    }

    /// Must be called with `lock` held.
    private func canPassLocked(_ route: any Route) -> Bool {
        guards.allSatisfy { $0.canNavigate(to: route) }
    }
}

/// Parses deep link URLs into routes using registered patterns.
public struct DeepLinkParser: Sendable {
    private var patterns: [(segments: [String], factory: @Sendable ([String: String]) -> any Route)] = []

    /// Creates a new deep link parser.
    public init() {}

    /// Registers a URL pattern with parameter placeholders (`:paramName`).
    /// - Parameters:
    ///   - pattern: A path pattern like `/users/:id/profile`.
    ///   - routeFactory: A closure that builds a `Route` from extracted parameters.
    public mutating func register(pattern: String, routeFactory: @escaping @Sendable ([String: String]) -> any Route) {
        let segments = pattern.split(separator: "/").map(String.init)
        patterns.append((segments: segments, factory: routeFactory))
    }

    /// Parses a URL string against registered patterns.
    ///
    /// Query strings (`?...`) and fragments (`#...`) are stripped from the path
    /// before pattern matching, so `app/users/42?foo=bar#section` matches the
    /// same patterns as `app/users/42`.
    ///
    /// - Parameter url: The URL string to parse.
    /// - Returns: A matching `Route` with extracted parameters, or `nil` if no pattern matches.
    public func parse(_ url: String) -> (any Route)? {
        // Strip fragment first, then query string.
        var path = url
        if let hashIdx = path.firstIndex(of: "#") { path = String(path[path.startIndex..<hashIdx]) }
        if let queryIdx = path.firstIndex(of: "?") { path = String(path[path.startIndex..<queryIdx]) }
        let urlSegments = path.split(separator: "/").map(String.init)
        for entry in patterns {
            if let params = match(urlSegments: urlSegments, patternSegments: entry.segments) {
                return entry.factory(params)
            }
        }
        return nil
    }

    private func match(urlSegments: [String], patternSegments: [String]) -> [String: String]? {
        guard urlSegments.count == patternSegments.count else { return nil }
        var params: [String: String] = [:]
        for (url, pattern) in zip(urlSegments, patternSegments) {
            if pattern.hasPrefix(":") {
                let key = String(pattern.dropFirst())
                params[key] = url
            } else if url != pattern {
                return nil
            }
        }
        return params
    }
}
