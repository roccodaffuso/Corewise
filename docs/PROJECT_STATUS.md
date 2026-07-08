# Corewise Project Status

Last updated: 2026-07-08

## Summary

Corewise is an early macOS SwiftUI MVP. The app shell, diagnostic pages, richer data model, charts, live CPU/RAM process sampling, safe battery basics, startup volume storage, and launch plist inventory exist locally. Runtime diagnostics no longer use synthetic values.

The immediate priority is trust: the UI and docs must make it obvious which values are live, planned, unavailable, or avoided by design.

Baseline checkpoint: `34315cf` (`Checkpoint Corewise diagnostic MVP`).
MVP trust baseline: `996af98` (`Stabilize Corewise trust baseline`).

## Implemented

- SwiftPM macOS app target named `Corewise`.
- SwiftUI navigation shell with sections for Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Settings.
- Diagnostic data model with title, value, unit, status, severity score, explanation, source, confidence, recommended action, and last updated.
- Live sampler for system CPU, system RAM, top CPU process groups, and top RAM process groups.
- Short in-memory performance history for sustained high CPU interpretation.
- Live uptime from `ProcessInfo.systemUptime`.
- App-bundle grouping for process helpers when a `.app` path is readable.
- Live battery basics from IOKit power-source APIs: charge, power source, and charging state when an internal battery exists.
- Structured `DataMode` provenance for visible diagnostic values.
- Read-only live storage collector for startup volume capacity only; personal folders are not scanned automatically.
- Read-only startup plist inventory for accessible LaunchAgents and LaunchDaemons metadata.
- Live high-level thermal state from `ProcessInfo.thermalState`.
- Read-only, manual-action product stance.

## Planned

- Expand visible provenance coverage as new row types are added.
- Add real health scoring after enough section data is live.
- Add explicit targeted storage scans only after a user action and clear permission copy.
- Expand battery only where documented safe public data is available; do not infer health details.
- Broaden startup beyond plist inventory only where macOS exposes safe public visibility.
- Add permitted diagnostic report reading for App Issues.
- Add memory pressure, swap, WindowServer interpretation, and thermal contributor attribution only through safe sources.
- Keep unavailable wattage clearly marked unless a safe, user-approved source exists.

## Unavailable

- Battery cycle count, maximum capacity, and condition through the current safe power-source collector.
- Modern login items, background items, privileged helpers, and startup code signing checks.
- Detailed storage categories that require broad or permission-limited scans.
- Crash counts, bundle IDs, app versions, and last crash dates.

## Avoided

- Private temperature sensors for consumer-facing claims.
- Sudo-only data collection.
- Automatic file deletion.
- Forced process termination.
- Backend accounts, analytics, or tracking.

## Current Risks

- Many areas are intentionally unavailable or planned, so the UI is sparser than a finished diagnostic app.
- Storage details are intentionally sparse until a permission-aware targeted scan exists.
- Health score is not calculated yet and must not be presented as a final diagnostic score.
- The current branch now has a checkpoint baseline plus additional stabilization changes in progress.
