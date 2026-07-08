# Corewise Project Status

Last updated: 2026-07-08

## Summary

Corewise is an early macOS SwiftUI MVP. The app shell, diagnostic pages, richer data model, charts, live CPU/RAM process sampling, process table, observed process memory, physical-footprint reads when available, safe battery basics, opportunistic battery health keys, startup volume storage, manual storage folder scans, manual crash report parsing, and launch plist inventory exist locally. Runtime diagnostics no longer use synthetic values.

The immediate priority is trust: the UI and docs must make it obvious which values are live, planned, unavailable, or avoided by design.

Baseline checkpoint: `34315cf` (`Checkpoint Corewise diagnostic MVP`).
MVP trust baseline: `996af98` (`Stabilize Corewise trust baseline`).
Real-data acquisition baseline pushed: `db21865` (`Add real data acquisition flows`).
Current state: real-data acquisition started; Performance parity is partially implemented through live process rows, observed memory, RSS, and footprint, but Corewise still does not claim exact Activity Monitor parity.

## Implemented

- SwiftPM macOS app target named `Corewise`.
- SwiftUI navigation shell with sections for Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Settings.
- Diagnostic data model with title, value, unit, status, severity score, explanation, source, confidence, recommended action, and last updated.
- Live sampler for system CPU split, system VM memory fields, process rows, app groups, observed process memory, resident memory, and physical footprint when macOS returns it.
- Short in-memory performance history for sustained high CPU interpretation.
- Live uptime from `ProcessInfo.systemUptime`.
- App-bundle grouping for process helpers when a `.app` path is readable.
- Live battery basics from IOKit power-source APIs: charge, power source, and charging state when an internal battery exists.
- Opportunistic battery health context from safe IOKit registry keys when present: cycle count, maximum capacity, and condition.
- Structured `DataMode` provenance for visible diagnostic values.
- Read-only live storage collector for startup volume capacity only; personal folders are not scanned automatically.
- User-selected read-only storage folder scan for largest folders/files, total scanned size, item count, unreadable count, and scan duration.
- Read-only startup plist inventory for accessible LaunchAgents and LaunchDaemons metadata.
- Live swap usage. Memory pressure is unavailable until a reliable public parity source is selected.
- Live high-level thermal state from `ProcessInfo.thermalState`.
- User-selected crash report metadata parsing for crash counts and repeated app patterns.
- Read-only, manual-action product stance.

## Planned

- Expand visible provenance coverage as new row types are added.
- Add real health scoring after enough section data is live.
- Refine manual storage scan UX after real use; do not add automatic personal-folder scanning.
- Broaden startup beyond plist inventory only where macOS exposes safe public visibility.
- Add WindowServer interpretation and thermal contributor attribution only through safe sources.
- Keep unavailable wattage clearly marked unless a safe, user-approved source exists.

## Unavailable

- Modern login items, background items, and privileged helper inventory. Startup code signing is best-effort only when a readable executable path is present.
- Automatic detailed storage categories that require broad or permission-limited scans.
- Crash counts before a reports folder is selected.

## Avoided

- Private temperature sensors for consumer-facing claims.
- Sudo-only data collection.
- Automatic file deletion.
- Forced process termination.
- Backend accounts, analytics, or tracking.

## Current Risks

- Many areas are intentionally unavailable or planned, so the UI is sparser than a finished diagnostic app.
- Performance values are closer to Monitoraggio Attività than before, but Corewise still uses public APIs and should not claim sysmond-level parity. The primary process memory value is observed memory, defined as the larger public value between footprint and RSS.
- Storage details depend on a user-selected folder and should not be mistaken for full-disk analysis.
- Crash report details depend on a user-selected folder and may miss reports outside that folder.
- Health score is not calculated yet and must not be presented as a final diagnostic score.
- The current branch now has a checkpoint baseline plus additional stabilization changes in progress.
