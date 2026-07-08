# Corewise

Corewise is a SwiftUI macOS utility that explains what a Mac is doing in plain language. It is local-first, has no account, no backend, and no tracking.

The current build is a trust-first product prototype. Runtime values are either live, planned, unavailable, or avoided; Corewise no longer shows synthetic diagnostic data as if it came from the Mac.

## Current Truth

Implemented live signals:

- Overview `Live Signals` header plus a first-viewport signal grid for CPU, memory, swap, top CPU process, top memory process, storage free space, battery, and thermal state.
- Data Access overview for live, user-selected, planned, unavailable, and avoided data paths. This supports trust but is not the primary first-viewport content.
- System CPU load and user/system/idle split from macOS CPU ticks.
- System RAM fields from VM statistics: used, app memory, cached files, wired, compressed, and swap.
- Live process table with PID, user, thread count, CPU %, observed memory, RSS, and physical footprint when macOS returns it.
- Performance page optimized around the question "what is slowing my Mac right now", with compact top pressure rows and a dense process table.
- App grouping derived from real process rows, kept separate from individual process rows.
- Battery charge, power source, and charging state when an internal battery is exposed by macOS power-source data.
- Battery cycle count, maximum capacity, and condition when safe battery registry keys are present.
- Startup volume total, used, available, and available percent.
- Startup volume breakdown as used vs available space.
- User-selected storage folder scan for largest folders/files, item count, unreadable count, and scan size.
- Short local performance history for sustained CPU interpretation.
- Live swap usage. Memory pressure remains unavailable until Corewise has a reliable public parity source.
- Read-only LaunchAgents and LaunchDaemons plist metadata where readable.
- High-level thermal state from `ProcessInfo.thermalState`.
- User-selected crash report folder parsing for app crash counts and repeated-crash patterns.
- Local Diagnostic Report page that copies Summary or Markdown text without uploads, stack traces, file contents, cleanup, or persistence.
- Lightweight menu bar monitor for CPU, memory, swap, and top process signals from the current app snapshot.

Planned or unavailable areas:

- Overall health score and cross-section prioritization. The Overview does not present this as a primary diagnosis until the scoring model is real.
- Battery energy impact and risk scoring.
- Automatic detailed storage folder scans, caches, Trash, and personal folder offenders.
- Modern login items, background items, privileged helpers, and startup code signing checks.
- WindowServer interpretation.
- Thermal contributors beyond high-level public thermal state.

Unavailable by design in the MVP:

- Whole-system wattage through private sensors, sudo-only tools, or unsupported APIs.
- Automatic Downloads or personal-folder scans during refresh.
- Automatic diagnostic report scans during refresh.
- Automatic deletion, forced app quitting, or destructive optimization.

## Build And Run

```sh
swift build
script/build_and_run.sh
```

The app target is defined in `Package.swift` and requires macOS 14 or newer.

## Performance Semantics

Corewise uses public macOS APIs, not private `sysmond` internals. Process rows are real, but they are not promised to match Monitoraggio Attività bit-for-bit. The primary memory value is `observed memory`: the larger public value between physical footprint and resident memory, with RSS still shown separately. System memory used is derived from app memory, wired memory, and compressed memory; cached files are shown separately because macOS can reclaim much of that memory.

## Product Workflows

Corewise is organized around three trustworthy workflows:

- Performance: understand CPU, memory, swap, and which live process rows are active.
- Storage Scan: choose a folder, inspect the largest real files and folders, and reveal items in Finder manually.
- Diagnostic Report: copy a local Summary or Markdown report for review without collecting stack traces or file contents.
- Menu Bar: glance at the same live CPU, memory, swap, and top process values without opening a second diagnostic surface.

## Project Docs

- `PRODUCT.md` defines positioning and design principles.
- `docs/PROJECT_STATUS.md` records the current product state and risks.
- `docs/ARCHITECTURE.md` explains the SwiftUI shell, store, collectors, and data flow.
- `docs/DATA_SOURCES.md` is the source-of-truth matrix for live, planned, unavailable, and avoided signals.
- `docs/SAFETY_PRIVACY.md` defines the local-first and non-destructive rules.
- `docs/DESIGN_SYSTEM.md` captures the intended Apple-native diagnostic UI.
- `docs/ROADMAP.md` orders the next implementation phases.
- `docs/DECISIONS.md` records product and technical decisions.

## Operating Rule

Every diagnostic value must be labeled honestly as `Live`, `Planned`, `Unavailable`, or `Avoided`. If Corewise cannot read a signal through safe public macOS APIs, it should say so and offer a manual review path instead of implying certainty.
