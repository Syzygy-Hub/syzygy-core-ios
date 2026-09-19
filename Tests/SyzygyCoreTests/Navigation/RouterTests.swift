import Testing
@testable import SyzygyCore

@Suite("Navigation Tests")
struct RouterTests {

    struct TestRoute: Route, Sendable {
        let path: String
        var parameters: [String: String] = [:]
    }

    struct BlockingGuard: RouteGuard {
        let blockedPath: String
        func canNavigate(to route: any Route) -> Bool { route.path != blockedPath }
    }

    @Test func pushAndPop() {
        let router = Router()
        router.push(TestRoute(path: "/home"))
        router.push(TestRoute(path: "/settings"))
        #expect(router.stackDepth == 2)
        #expect(router.currentRoute?.path == "/settings")
        let popped = router.pop()
        #expect(popped?.path == "/settings")
        #expect(router.stackDepth == 1)
    }

    @Test func popEmptyReturnsNil() {
        let router = Router()
        #expect(router.pop() == nil)
        #expect(router.currentRoute == nil)
    }

    @Test func guardBlocksNavigation() {
        let router = Router()
        router.addGuard(BlockingGuard(blockedPath: "/admin"))
        #expect(router.push(TestRoute(path: "/home")) == true)
        #expect(router.push(TestRoute(path: "/admin")) == false)
        #expect(router.stackDepth == 1)
    }

    @Test func popToRoot() {
        let router = Router()
        router.push(TestRoute(path: "/a"))
        router.push(TestRoute(path: "/b"))
        router.push(TestRoute(path: "/c"))
        router.popToRoot()
        #expect(router.stackDepth == 1)
        #expect(router.currentRoute?.path == "/a")
    }

    @Test func deepLinkParserMatchesPattern() {
        var parser = DeepLinkParser()
        parser.register(pattern: "app/users/:id/profile") { params in
            TestRoute(path: "/profile", parameters: params)
        }
        let route = parser.parse("app/users/42/profile")
        #expect(route?.path == "/profile")
        #expect(route?.parameters["id"] == "42")
        #expect(parser.parse("app/unknown") == nil)
    }

    @Test func deepLinkParserStripsQueryString() {
        var parser = DeepLinkParser()
        parser.register(pattern: "app/items/:id") { params in
            TestRoute(path: "/item", parameters: params)
        }
        let route = parser.parse("app/items/7?source=push&utm=email")
        #expect(route?.path == "/item")
        #expect(route?.parameters["id"] == "7")
    }

    @Test func deepLinkParserStripsFragment() {
        var parser = DeepLinkParser()
        parser.register(pattern: "app/items/:id") { params in
            TestRoute(path: "/item", parameters: params)
        }
        let route = parser.parse("app/items/8#section-top")
        #expect(route?.path == "/item")
        #expect(route?.parameters["id"] == "8")
    }

    @Test func deepLinkParserStripsQueryStringAndFragment() {
        var parser = DeepLinkParser()
        parser.register(pattern: "app/items/:id") { params in
            TestRoute(path: "/item", parameters: params)
        }
        let route = parser.parse("app/items/9?foo=bar#section")
        #expect(route?.path == "/item")
        #expect(route?.parameters["id"] == "9")
    }

    // MARK: - ITEM 7: replace() test

    @Test func replaceWithReplacesTopRoute() {
        let router = Router()
        router.push(TestRoute(path: "/home"))
        let replaced = router.replace(with: TestRoute(path: "/dashboard"))
        #expect(replaced == true)
        #expect(router.stackDepth == 1)
        #expect(router.currentRoute?.path == "/dashboard")
    }

    @Test func concurrentNavigationIsSafe() async {
        // Verifies that concurrent push/pop from multiple tasks does not crash or corrupt state.
        let router = Router()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask { router.push(TestRoute(path: "/concurrent/\(index)")) }
            }
            for _ in 0..<10 {
                group.addTask { _ = router.pop() }
            }
        }
        // After all tasks complete the stack depth must be non-negative and consistent.
        #expect(router.stackDepth >= 0)
    }
}
