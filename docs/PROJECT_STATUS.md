# Corewise Project Status

Last updated: 2026-07-09

## Summary

Corewise is an early macOS SwiftUI MVP. The app shell, diagnostic pages, richer data model, charts, Overview Live Signals header, live CPU/RAM process sampling, process table, observed process memory, physical-footprint and page-ins reads when available, Swap Insight, safe battery basics, opportunistic battery health keys, startup volume storage, manual storage folder scans, manual crash report parsing, launch plist inventory, local Summary/Markdown diagnostic report, and lightweight menu bar monitor exist locally. Runtime diagnostics no longer use synthetic values.

The immediate priority is product trust: Corewise should feel like a diagnostic workflow, not a complete but shallow dashboard. The main workflow direction is Performance first, manual Storage Scan second, and local Diagnostic Report third.

Baseline checkpoint: `34315cf` (`Checkpoint Corewise diagnostic MVP`).
MVP trust baseline: `996af98` (`Stabilize Corewise trust baseline`).
Real-data acquisition baseline pushed: `db21865` (`Add real data acquisition flows`).
Current state: real-data acquisition started; Performance parity is partially implemented through live process rows, observed memory, RSS, and footprint, but Corewise still does not claim exact Activity Monitor parity.
Product realignment: after last30days research, Corewise is positioned as local diagnostics and explanation, not automatic cleanup or Activity Monitor exact parity.
Remaining last30days work batch completed locally through `fa4e241`: Performance explanations, Storage exploration, Report quality, Startup/App Issues readability, and a light menu bar monitor are implemented. Score remains gated.
Swap Insight baseline: committed as `Add Swap Insight diagnostics`.

## Implemented

- SwiftPM macOS app target named `Corewise`.
- SwiftUI navigation shell with sections for Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Report, plus a native Settings scene and lightweight menu bar monitor.
- Diagnostic data model with title, value, unit, status, severity score, explanation, source, confidence, recommended action, and last updated.
- Overview leads with `Live Signals`, concrete first-viewport system signals, and signal-family coverage instead of a placeholder health score. Coverage intentionally does not count every process or table row.
- Live sampler for system CPU split, system VM memory fields, system swap fields, process rows, app groups, observed process memory, resident memory, physical footprint, and page-ins when macOS returns them. Process enumeration now uses `sysctl KERN_PROC_ALL` first so renderer/helper processes are less likely to be missed.
- Performance explanations derive plain-language process insights from live process rows for helpers/renderers, Electron-style apps, WindowServer, Spotlight, file provider sync, and Corewise itself.
- Short in-memory performance history for sustained high CPU interpretation.
- Live uptime from `ProcessInfo.systemUptime`.
- App-bundle grouping for process helpers when a `.app` path is readable.
- Live battery basics from IOKit power-source APIs: charge, power source, and charging state when an internal battery exists.
- Opportunistic battery health context from safe IOKit registry keys when present: cycle count, maximum capacity, and condition.
- Structured `DataMode` provenance for visible diagnostic values.
- Read-only live storage collector for startup volume capacity only; personal folders are not scanned automatically.
- User-selected read-only storage folder scan with session-only folder explorer, breadcrumbs, drilldown into largest folders, parent navigation, largest files, total scanned size, item count, unreadable count, and scan duration.
- Read-only startup plist inventory for accessible LaunchAgents and LaunchDaemons metadata, shown as a compact table with label, kind, executable, startup impact, trust state, and Finder reveal.
- Swap Insight in `Performance > Memory`: system swap used/total/available, trend, swap in/out rates, swapped VM pages, encryption state, and likely memory-pressure contributors. Corewise does not claim exact per-process swap ownership.
- Memory pressure is unavailable until a reliable public parity source is selected.
- Live high-level thermal state from `ProcessInfo.thermalState`.
- User-selected crash report metadata parsing for crash counts and repeated app patterns, with a strong empty state before reports are selected.
- Local Diagnostic Report page with `Summary / Markdown` views, notable findings, manual next steps, source/confidence notes, and clipboard-only copy without stack traces, uploads, file contents, or cleanup actions.
- Native SwiftUI Settings scene has compact General, Privacy & Data, Performance, Report, and Menu Bar tabs, reachable from the macOS Settings command and a footer link below the diagnostic sidebar navigation. Settings controls display/report preferences only and does not change automatic data collection.
- Read-only, manual-action product stance.

## Planned

- Expand visible provenance coverage as new row types are added.
- Add real health scoring after enough section data is live.
- Refine manual storage scan UX after real use; do not add automatic personal-folder scanning.
- Broaden startup beyond plist inventory only where macOS exposes safe public visibility.
- Add WindowServer interpretation and thermal contributor attribution only through safe sources.
- Keep unavailable wattage clearly marked unless a safe, user-approved source exists.
- Refine menu bar monitor copy and behavior after manual app QA.
- Keep Settings preferences small and local; consider launch-at-login, refresh interval, or remembered folders only after separate safety decisions.

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
- Performance values are closer to Monitoraggio Attività than before, but Corewise still uses public APIs and should not claim sysmond-level parity. The primary process memory value is observed memory, defined as the larger public value between footprint and RSS. Swap Insight is useful pressure context, not process-level swap attribution.
- Storage details depend on a user-selected folder and should not be mistaken for full-disk analysis.
- Crash report details depend on a user-selected folder and may miss reports outside that folder.
- Health score is not calculated yet and must not be presented as a final diagnostic score; Overview should continue emphasizing live signals and coverage.
- Report copy is a current-snapshot summary, not a full support bundle or persistent diagnostic archive. It now has a short summary view and a fuller Markdown view, both generated from the same snapshot.
