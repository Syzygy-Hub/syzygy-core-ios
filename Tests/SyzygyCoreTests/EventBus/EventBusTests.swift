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

@Suite("Event Bus Tests")
struct EventBusTests {

    struct TestEvent: Sendable { let value: Int }
    struct OtherEvent: Sendable { let name: String }

    @Test func publishDeliversToSubscribers() {
        let bus = EventBus()
        let received = Box<[Int]>([])
        let token = bus.subscribe(to: TestEvent.self) { event in
            received.mutate { $0.append(event.value) }
        }
        bus.publish(TestEvent(value: 42))
        #expect(received.value == [42])
        _ = token
    }

    @Test func subscriberOnlyReceivesMatchingType() {
        let bus = EventBus()
        let testEvents = Box<[Int]>([])
        let otherEvents = Box<[String]>([])
        let t1 = bus.subscribe(to: TestEvent.self) { event in testEvents.mutate { $0.append(event.value) } }
        let t2 = bus.subscribe(to: OtherEvent.self) { event in otherEvents.mutate { $0.append(event.name) } }
        bus.publish(TestEvent(value: 1))
        bus.publish(OtherEvent(name: "hello"))
        #expect(testEvents.value == [1])
        #expect(otherEvents.value == ["hello"])
        _ = (t1, t2)
    }

    @Test func cancelStopsDelivery() {
        let bus = EventBus()
        let received = Box<[Int]>([])
        let token = bus.subscribe(to: TestEvent.self) { event in received.mutate { $0.append(event.value) } }
        bus.publish(TestEvent(value: 1))
        token.cancel()
        bus.publish(TestEvent(value: 2))
        #expect(received.value == [1])
        #expect(token.isCancelled)
    }

    @Test func tokenDeinitCancelsSubscription() {
        let bus = EventBus()
        let received = Box<[Int]>([])
        do {
            let token = bus.subscribe(to: TestEvent.self) { event in received.mutate { $0.append(event.value) } }
            bus.publish(TestEvent(value: 1))
            _ = token
        }
        bus.publish(TestEvent(value: 2))
        #expect(received.value == [1])
    }
}
