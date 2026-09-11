import Testing
import Foundation
@testable import SyzygyCore

@Suite("Event Bus Tests")
struct EventBusTests {

    struct TestEvent: Sendable { let value: Int }
    struct OtherEvent: Sendable { let name: String }

    @Test func publishDeliversToSubscribers() async {
        let bus = EventBus()
        let received = Box<[Int]>([])
        let token = bus.subscribe(to: TestEvent.self) { event in
            received.mutate { $0.append(event.value) }
        }
        bus.publish(TestEvent(value: 42))
        await Task.yield()
        #expect(received.value == [42])
        _ = token
    }

    @Test func subscriberOnlyReceivesMatchingType() async {
        let bus = EventBus()
        let testEvents = Box<[Int]>([])
        let otherEvents = Box<[String]>([])
        let t1 = bus.subscribe(to: TestEvent.self) { event in testEvents.mutate { $0.append(event.value) } }
        let t2 = bus.subscribe(to: OtherEvent.self) { event in otherEvents.mutate { $0.append(event.name) } }
        bus.publish(TestEvent(value: 1))
        bus.publish(OtherEvent(name: "hello"))
        await Task.yield()
        #expect(testEvents.value == [1])
        #expect(otherEvents.value == ["hello"])
        _ = (t1, t2)
    }

    @Test func cancelStopsDelivery() async {
        let bus = EventBus()
        let received = Box<[Int]>([])
        let token = bus.subscribe(to: TestEvent.self) { event in received.mutate { $0.append(event.value) } }
        bus.publish(TestEvent(value: 1))
        await Task.yield()
        token.cancel()
        bus.publish(TestEvent(value: 2))
        await Task.yield()
        #expect(received.value == [1])
        #expect(token.isCancelled)
    }

    @Test func tokenDeinitCancelsSubscription() async {
        let bus = EventBus()
        let received = Box<[Int]>([])
        do {
            let token = bus.subscribe(to: TestEvent.self) { event in received.mutate { $0.append(event.value) } }
            bus.publish(TestEvent(value: 1))
            await Task.yield()
            _ = token
        }
        bus.publish(TestEvent(value: 2))
        await Task.yield()
        #expect(received.value == [1])
    }
}
