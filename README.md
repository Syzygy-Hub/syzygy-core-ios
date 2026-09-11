[![iOS](https://img.shields.io/badge/iOS-Swift-7F77DD?style=flat)](https://developer.apple.com/ios/) [![Swift](https://img.shields.io/badge/Swift-6.0-1D9E75?logo=swift&logoColor=white&style=flat)](https://swift.org) [![CI](https://img.shields.io/github/actions/workflow/status/Syzygy-Hub/syzygy-core-ios/ci.yml?label=ci&style=flat)](https://github.com/Syzygy-Hub/syzygy-core-ios/actions/workflows/ci.yml) [![Version](https://img.shields.io/badge/version-1.1.0-D85A30?style=flat)](https://github.com/Syzygy-Hub/syzygy-core-ios/releases) [![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Syzygy-Hub/.github/main/brand/assets/banners/syzygy-banner-dark-1200.png">
  <img src="https://raw.githubusercontent.com/Syzygy-Hub/.github/main/brand/assets/banners/syzygy-banner-light-1200.png" alt="Syzygy" width="600">
</picture>

# syzygy-core-ios

Core infrastructure modules for the Syzygy iOS ecosystem — dependency injection, state management, event bus, logging, feature flags, navigation, validation, configuration, app lifecycle, and scheduling.

---

## Modules

| Module | Description |
|---|---|
| **DI** | Thread-safe dependency injection container with singleton, transient, and scoped lifetimes |
| **State** | Reactive state stores, observable properties, state reducers, and selectors |
| **EventBus** | Typed publish/subscribe channels with scoped subscriptions and async dispatch |
| **Logging** | Log levels, formatters, pipeline routing, and pluggable destinations |
| **FeatureFlags** | Evaluation rules, flag definitions, local overrides, and A/B variant selection |
| **Navigation** | Route definitions, deep link URL parsing, navigation stack model, and route guards |
| **Validation** | Composable field validators, rule chaining, and form-level validation pipeline |
| **Configuration** | In-memory config registry, environment-based switching, and typed config access |
| **Lifecycle** | Foreground/background state tracking, lifecycle observers, and lifecycle-aware scoping |
| **Scheduling** | Debounce, throttle, delayed execution, and cancellable timers |

---

## Installation

Add the dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Syzygy-Hub/syzygy-core-ios", from: "1.1.0")
]
```

Then add `SyzygyCore` to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SyzygyCore", package: "syzygy-core-ios")
    ]
)
```

---

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.0+
- Xcode 16.0+

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| [syzygy-foundation-ios](https://github.com/Syzygy-Hub/syzygy-foundation-ios) | 1.1.0 | Foundation contracts, primitives, and shared types |

---

## Ecosystem

This repo is part of the **Syzygy** cross-platform mobile ecosystem. See the [ecosystem architecture](https://github.com/Syzygy-Hub/.github/blob/main/engineering/architecture/syzygy-ecosystem.md) for how the layers fit together.

---

## License

MIT — see [LICENSE](LICENSE) for details.
