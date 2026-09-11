# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-11

### Fixed

- FIX 2: StateStore.observe() TOCTOU race — continuation is now registered inside the lock before the current state is yielded, preventing missed dispatches concurrent with a new observe() call
- FIX 3: Router thread safety — added NSLock protection to all mutations of stack and guards arrays; removed @unchecked Sendable; added Sendable constraint to RouteGuard protocol
- FIX 7: LogDestination.write() extended to carry timestamp and Error — new signature write(level:message:metadata:timestamp:error:) with defaults nil; ConsoleLogDestination outputs timestamp and error; Logger bridge forwards entry.timestamp and entry.error
- FIX 8: Added test coverage for log(LogEntry) Foundation path — all 5 LogLevel mappings, metadata forwarding, timestamp forwarding
- FIX 9: Injected clock into Throttler — new clock parameter enables deterministic testing; added post-cooldown execution test
- FIX 13: DeepLinkParser strips query strings and fragments before pattern matching
- FIX 15: RegexValidator now calls preconditionFailure on invalid pattern instead of silently returning invalid
- FIX 16: Scoped DI lifetime isolation documented in Container.swift; added tests for independent child scopes and parent-scope caching
- FIX 19: ValidationPipeline.collectAll tests fixed — replaced mutually-exclusive constraints with valid MinLength+MaxLength combinations covering 0, 1, and 2 errors
- FIX 20: EmailValidator doc comment added stating heuristic limitations
- FIX 21: Box<T> test helper deduplicated into Tests/SyzygyCoreTests/TestSupport/Box.swift
- FIX 22: Silent as? casts in InMemoryFeatureFlagProvider and ConfigRegistry replaced with guard-let + diagnostic message on type mismatch

[1.1.0]: https://github.com/Syzygy-Hub/syzygy-core-ios/releases/tag/1.1.0

## [1.0.0] - 2026-09-05

### Added

- DI container with singleton, transient, and scoped lifetimes
- Reactive state stores with reducers and selectors
- Typed event bus with scoped subscriptions and async dispatch
- Logger with log levels, formatters, and pluggable destinations
- Feature flag provider with evaluation rules, local overrides, and A/B variants
- Navigation router with deep link parsing and route guards
- Composable validation pipeline with built-in rules
- Configuration registry with environment-based switching
- App lifecycle tracker with lifecycle-aware scoping
- Scheduling utilities — debounce, throttle, delayed execution, cancellable timers

[1.0.0]: https://github.com/Syzygy-Hub/syzygy-core-ios/releases/tag/1.0.0
