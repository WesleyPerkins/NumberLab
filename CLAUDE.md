# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

**Build:**
```
xcodebuild -project NumberLab.xcodeproj -scheme NumberLab build
```

**Run all tests:**
```
xcodebuild test -project NumberLab.xcodeproj -scheme NumberLab -destination 'platform=macOS'
```

**Run a single test:**
```
xcodebuild test -project NumberLab.xcodeproj -scheme NumberLab -destination 'platform=macOS' -only-testing:NumberLabTests/NumberLabTests/<TestMethodName>
```

No linting or formatting tools are configured — Xcode's built-in warnings are the primary code quality check.

## Architecture Overview

NumberLab is a macOS/iOS SwiftUI app for exploring the Collatz conjecture and related number theory. It has three layers:

### `NumberTheory/` — Core math engine
The heart of the app. All computation happens here, with no external dependencies.

- **`N.swift`** — The foundational `N` class represents arbitrary-precision natural numbers using a custom bit-level linked list (`BitChain`). Implements `+`, `*`, `-`, comparison, and division by 3. All other number types build on this.
- **`BitChain.swift`** — Doubly-linked list of bits, the binary representation backing `N`. Uses a free-list memory pool (`BitLink`) to avoid allocation overhead during intensive operations.
- **`Odd.swift`** — Subclass of `N` for odd numbers. Owns the Collatz logic: `collatz()` applies 3n+1 in-place, `collatzChain()` returns the full sequence to 1, and `collatzProbability()` generates histograms of chain lengths over large samples.
- **`Partition.swift`** — Large (800 lines), self-contained combinatorial partition engine. Generates integer partitions under various constraints (odd parts, distinct parts, modulo residues). Uses heavy memoization.
- **`Histogram.swift`** — Bins data into a probability distribution; used by `collatzProbability()`.
- **`CollatzMap.swift`** — Memoizes Collatz paths to 1 to accelerate repeated lookups.

### `View/` — SwiftUI presentation
- **`ContentView.swift`** — Sidebar-style navigation hub with 5 sections.
- **`ChainView.swift`** — Displays Collatz chains for the first N odd numbers, instrumented with `TimeProfiler`.
- **`HistogramView.swift`** — Interactive histogram of chain lengths for 30-, 100-, or 200-bit random numbers.
- **`BitStringView.swift`** — Shows the binary representation evolving through a Collatz sequence.

### `Utl/` — Utilities
- **`TimeProfiler.swift`** — Benchmarks execution by named state transitions; used in views to surface performance data.
- **`CgUtl.swift`** — CoreGraphics geometry extensions used in custom drawing.
- **`Stack.swift`** — Generic stack used in number theory algorithms.

## Key Design Decisions

- **Custom big-integer representation**: `N` does not use Swift's built-in integers or any third-party big-number library. The doubly-linked `BitChain` was chosen to support efficient bit-level manipulation (shifting, appending, removing leading zeros) during Collatz operations.
- **`Odd` as a subclass of `N`**: Collatz-specific behavior lives in `Odd` rather than `N` to keep the base number type general-purpose.
- **In-place mutation**: `collatz()` mutates the `Odd` in place; callers that need to preserve the original must copy first.
- **Memory pooling in `BitChain`**: The free-list allocator in `BitChain` is intentional — during histogram runs over thousands of large numbers, allocation pressure would otherwise dominate runtime.
