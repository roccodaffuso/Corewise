# Corewise Project Status

Last updated: 2026-07-08

## Summary

Corewise is an early macOS SwiftUI MVP. The app shell, diagnostic pages, richer data model, charts, and live CPU/RAM process sampling exist locally. Most non-performance diagnostics still use realistic mock data.

The immediate priority is trust: the UI and docs must make it obvious which values are live, which are mock, which are planned, and which are unavailable by design.

## Implemented

- SwiftPM macOS app target named `Corewise`.
- SwiftUI navigation shell with sections for Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Settings.
- Diagnostic data model with title, value, unit, status, severity score, explanation, source, confidence, recommended action, and last updated.
- Live sampler for system CPU, system RAM, top CPU process groups, and top RAM process groups.
- App-bundle grouping for process helpers when a `.app` path is readable.
- Read-only, manual-action product stance.

## Mock

- Health score and overall status.
- Battery cycles, capacity, condition, charge state, energy impact, and risk.
- Storage totals, breakdown, large folders, large files, caches, backups, and developer data.
- Startup/login/background/privileged helper inventory.
- Memory pressure, swap, uptime, sustained CPU history, and WindowServer interpretation.
- Thermal contributor attribution.
- Crash counts, bundle IDs, app versions, repeated crash flags, and diagnostic permission state.

## Planned

- Add visible `Live`, `Mock`, and `Unavailable` badges at metric and row level.
- Replace storage mocks with a read-only scanner that requires no destructive action.
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

- Some fallback process rows can still be mock if live process sampling returns no rows; the UI must label that path clearly before broader testing.
- Mock storage examples can look personal if not visibly labeled.
- Health score currently mixes live and mock signals, so it must not be presented as a final diagnostic score.
- The working tree contains active product changes that are not yet a stable release boundary.
