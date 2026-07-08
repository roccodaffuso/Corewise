# Corewise Project Status

Last updated: 2026-07-08

## Summary

Corewise is an early macOS SwiftUI MVP. The app shell, diagnostic pages, richer data model, charts, Overview Live Signals header, live CPU/RAM process sampling, process table, observed process memory, physical-footprint reads when available, safe battery basics, opportunistic battery health keys, startup volume storage, manual storage folder scans, manual crash report parsing, launch plist inventory, and a local Markdown diagnostic report exist locally. Runtime diagnostics no longer use synthetic values.

The immediate priority is product trust: Corewise should feel like a diagnostic workflow, not a complete but shallow dashboard. The main workflow direction is Performance first, manual Storage Scan second, and local Diagnostic Report third.

Baseline checkpoint: `34315cf` (`Checkpoint Corewise diagnostic MVP`).
MVP trust baseline: `996af98` (`Stabilize Corewise trust baseline`).
Real-data acquisition baseline pushed: `db21865` (`Add real data acquisition flows`).
Current state: real-data acquisition started; Performance parity is partially implemented through live process rows, observed memory, RSS, and footprint, but Corewise still does not claim exact Activity Monitor parity.
Product realignment: after last30days research, Corewise is positioned as local diagnostics and explanation, not automatic cleanup or Activity Monitor exact parity.
Remaining last30days work started: Corewise is now moving from realignment foundation into deeper workflow polish for Performance explanations, Storage exploration, Report quality, Startup/App Issues readability, and a light menu bar monitor.

## Implemented

- SwiftPM macOS app target named `Corewise`.
- SwiftUI navigation shell with sections for Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, Report, and Settings.
- Diagnostic data model with title, value, unit, status, severity score, explanation, source, confidence, recommended action, and last updated.
- Overview leads with `Live Signals`, concrete first-viewport system signals, and signal-family coverage instead of a placeholder health score. Coverage intentionally does not count every process or table row.
- Live sampler for system CPU split, system VM memory fields, process rows, app groups, observed process memory, resident memory, and physical footprint when macOS returns it. Process enumeration now uses `sysctl KERN_PROC_ALL` first so renderer/helper processes are less likely to be missed.
- Performance explanations derive plain-language process insights from live process rows for helpers/renderers, Electron-style apps, WindowServer, Spotlight, file provider sync, and Corewise itself.
- Short in-memory performance history for sustained high CPU interpretation.
- Live uptime from `ProcessInfo.systemUptime`.
- App-bundle grouping for process helpers when a `.app` path is readable.
- Live battery basics from IOKit power-source APIs: charge, power source, and charging state when an internal battery exists.
- Opportunistic battery health context from safe IOKit registry keys when present: cycle count, maximum capacity, and condition.
- Structured `DataMode` provenance for visible diagnostic values.
- Read-only live storage collector for startup volume capacity only; personal folders are not scanned automatically.
- User-selected read-only storage folder scan with session-only folder explorer, breadcrumbs, drilldown into largest folders, parent navigation, largest files, total scanned size, item count, unreadable count, and scan duration.
- Read-only startup plist inventory for accessible LaunchAgents and LaunchDaemons metadata.
- Live swap usage. Memory pressure is unavailable until a reliable public parity source is selected.
- Live high-level thermal state from `ProcessInfo.thermalState`.
- User-selected crash report metadata parsing for crash counts and repeated app patterns.
- Local Diagnostic Report page with `Summary / Markdown` views, notable findings, manual next steps, source/confidence notes, and clipboard-only copy without stack traces, uploads, file contents, or cleanup actions.
- Read-only, manual-action product stance.

## Planned

- Expand visible provenance coverage as new row types are added.
- Add real health scoring after enough section data is live.
- Refine manual storage scan UX after real use; do not add automatic personal-folder scanning.
- Broaden startup beyond plist inventory only where macOS exposes safe public visibility.
- Add WindowServer interpretation and thermal contributor attribution only through safe sources.
- Keep unavailable wattage clearly marked unless a safe, user-approved source exists.
- Menu bar monitor is a roadmap idea only; it is not part of this batch.

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
- Health score is not calculated yet and must not be presented as a final diagnostic score; Overview should continue emphasizing live signals and coverage.
- Report copy is a current-snapshot summary, not a full support bundle or persistent diagnostic archive. It now has a short summary view and a fuller Markdown view, both generated from the same snapshot.
