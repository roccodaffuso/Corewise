# Corewise

Corewise is a SwiftUI macOS utility that explains what a Mac is doing in plain language. It is local-first, has no account, no backend, and no tracking.

The current build is a product prototype with a small live performance collector and broad mock diagnostic coverage. Treat the UI as a working shell for the product direction, not as a complete device diagnostic.

## Current Truth

Implemented live signals:

- System CPU load from macOS CPU ticks.
- System RAM estimate from VM statistics.
- Top CPU process groups from public process information.
- Top RAM process groups from public process information.
- Process path lookup for grouping helpers under their owning `.app` bundle when available.
- Startup volume total, used, available, and available percent.
- Read-only sizes for selected known folders and large files where readable.
- High-level thermal state from `ProcessInfo.thermalState`.

Mock or scaffolded areas:

- Overall health score.
- Detailed battery health.
- Startup, login, agent, daemon, background item, and helper lists.
- Memory pressure, swap, sustained CPU history, and WindowServer interpretation.
- Thermal contributors beyond high-level public thermal state.
- Crash/app issue counts and repeated-crash patterns.

Unavailable by design in the MVP:

- Whole-system wattage through private sensors, sudo-only tools, or unsupported APIs.
- Automatic deletion, forced app quitting, or destructive optimization.

## Build And Run

```sh
swift build
script/build_and_run.sh
```

The app target is defined in `Package.swift` and requires macOS 14 or newer.

## Project Docs

- `PRODUCT.md` defines positioning and design principles.
- `docs/PROJECT_STATUS.md` records the current product state and risks.
- `docs/ARCHITECTURE.md` explains the SwiftUI shell, store, collectors, and data flow.
- `docs/DATA_SOURCES.md` is the source-of-truth matrix for live, mock, planned, and avoided signals.
- `docs/SAFETY_PRIVACY.md` defines the local-first and non-destructive rules.
- `docs/DESIGN_SYSTEM.md` captures the intended Apple-native diagnostic UI.
- `docs/ROADMAP.md` orders the next implementation phases.
- `docs/DECISIONS.md` records product and technical decisions.

## Operating Rule

Every diagnostic value must be labeled honestly as `Live`, `Mock`, `Planned`, or `Unavailable`. If Corewise cannot read a signal through safe public macOS APIs, it should say so and offer a manual review path instead of implying certainty.
