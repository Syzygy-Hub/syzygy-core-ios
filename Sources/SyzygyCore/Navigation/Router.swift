// MARK: - Navigation
// Route definitions, deep link URL parsing, navigation stack model, and route guards.

import SyzygyFoundation

/// A navigable route definition.
public protocol Route: Sendable {
    var path: String { get }
}

/// Parses deep link URLs into routes.
public struct DeepLinkParser {
    // TODO: URL pattern matching, parameter extraction
    public init() {}
}

/// Manages a navigation stack and applies route guards.
public final class Router: @unchecked Sendable {
    // TODO: stack model, push/pop/replace, route guards
    public init() {}
}
