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
}
