# Corewise Project Status

Last updated: 2026-07-08

## Summary

Corewise is an early macOS SwiftUI MVP. The app shell, diagnostic pages, richer data model, charts, and live CPU/RAM process sampling exist locally. Most non-performance diagnostics still use realistic mock data.

The immediate priority is trust: the UI and docs must make it obvious which values are live, which are mock, which are planned, and which are unavailable by design.

Baseline checkpoint: `34315cf` (`Checkpoint Corewise diagnostic MVP`).
MVP trust baseline: `cc8e83a` (`Stabilize Corewise trust baseline`).

## Implemented

- SwiftPM macOS app target named `Corewise`.
- SwiftUI navigation shell with sections for Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Settings.
- Diagnostic data model with title, value, unit, status, severity score, explanation, source, confidence, recommended action, and last updated.
- Live sampler for system CPU, system RAM, top CPU process groups, and top RAM process groups.
- App-bundle grouping for process helpers when a `.app` path is readable.
- Structured `DataMode` provenance for visible diagnostic values.
- Read-only live storage collector for startup volume capacity and selected known paths.
- Live high-level thermal state from `ProcessInfo.thermalState`.
- Read-only, manual-action product stance.

## Mock

- Health score and overall status.
- Battery cycles, capacity, condition, charge state, energy impact, and risk.
- Startup/login/background/privileged helper inventory.
- Memory pressure, swap, uptime, sustained CPU history, and WindowServer interpretation.
- Storage categories that require broad or permission-limited scans remain omitted rather than estimated.
- Thermal contributor attribution.
- Crash counts, bundle IDs, app versions, repeated crash flags, and diagnostic permission state.

## Planned

- Expand visible provenance coverage as new row types are added.
- Broaden storage scanning only where it stays read-only and clearly permission-limited.
- Replace battery mocks with safe public power-source and battery-health signals where available.
- Replace startup mocks with read-only inventory and clear permission limits.
- Replace crash mocks with permitted diagnostic report reading.
- Keep unavailable wattage clearly marked unless a safe, user-approved source exists.

## Avoided

- Private temperature sensors for consumer-facing claims.
- Sudo-only data collection.
- Automatic file deletion.
- Forced process termination.
- Backend accounts, analytics, or tracking.

## Current Risks

- Some mock section content remains in Battery, Startup, Performance secondary metrics, and App Issues.
- Read-only folder sizing may be slow on large known directories and needs UX tuning before release.
- Health score currently mixes live and mock signals, so it must not be presented as a final diagnostic score.
- The current branch now has a checkpoint baseline plus additional stabilization changes in progress.
