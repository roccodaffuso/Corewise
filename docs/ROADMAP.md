# Roadmap

## Phase 1: Trust And Provenance

- Implemented: explicit `Live`, `Planned`, `Unavailable`, and `Avoided` data modes in the model.
- Implemented: data-mode badges in metric cards, source notes, and diagnostic rows.
- Implemented: dense performance rows use a table-level source note instead of repeating `Live` badges on every row.
- Implemented: CPU/RAM process chart fallbacks removed.
- Implemented: runtime synthetic diagnostic data removed.
- Implemented: Overview leads with concrete live signals before Data Access education.
- Keep `DATA_SOURCES.md` synchronized with the UI.

## Phase 2: Storage Read-Only Collector

- Implemented: real total, used, available, and available-percent values.
- Implemented: automatic refresh reads startup volume capacity only.
- Implemented: Downloads, Trash, caches, and user Library folders are not scanned automatically.
- Implemented: explicit user-selected folder scan with largest folders/files, unreadable count, and scan duration.
- Implemented: scanned storage items can be revealed in Finder without deletion or file mutation.
- Planned: refine scan presets and optional security-scoped persistence only if the product needs it.
- Never delete, move, or modify files.

## Phase 3: Battery Collector

- Implemented: live charge, power source, and charging state from safe IOKit power-source data.
- Implemented: no-battery state and missing keys render unavailable values instead of placeholders.
- Implemented when present: cycle count, maximum capacity, and condition from safe IOKit battery registry keys.
- Keep service wording tied to macOS-provided state only.

## Phase 4: Performance History

- Implemented: live CPU split, VM memory fields, and dense process rows.
- Implemented: Performance is the main diagnostic page and is organized around "what is slowing my Mac right now".
- Implemented: process physical footprint through `proc_pid_rusage(RUSAGE_INFO_V4)` when macOS returns it.
- Implemented: observed process memory uses the larger public value between footprint and RSS, with RSS still visible.
- Implemented: app groups are derived from process rows and kept separate from the process table.
- Implemented: short local in-memory history for sustained CPU and repeated high process usage.
- Implemented: uptime from `ProcessInfo.systemUptime`.
- Implemented: swap usage from safe local VM signals.
- Unavailable: memory pressure until a reliable public parity source is selected.
- Keep WindowServer interpretation planned until there is enough context.

## Phase 4.5: Diagnostic Report

- Implemented: local Summary and Markdown report builder from the current snapshot.
- Implemented: Report page copies Summary or Markdown to the clipboard only.
- Implemented: notable findings, manual next steps, and source/confidence notes derived from existing snapshot data.
- Implemented: report excludes stack traces, raw crash contents, file contents, uploads, and cleanup actions.
- Planned: refine report grouping after real user review.

## Phase 5: Startup Inventory

- Implemented: read-only inventory for accessible LaunchAgents and LaunchDaemons plist metadata.
- Implemented: compact startup inventory table with label, kind, executable, impact, trust state, recent marker, and Finder reveal.
- Implemented when path is readable: best-effort startup executable signing state.
- Keep login items, background items, and privileged helpers planned/unavailable until safe collectors exist.
- Avoid raw deletion suggestions; route actions through System Settings, app settings, package managers, or uninstallers.

## Phase 6: Thermal And App Issues

- Implemented: use `ProcessInfo.thermalState` for safe high-level thermal state.
- Avoid private temperature sensors.
- Implemented: read crash report metadata only after the user selects a reports folder.
- Implemented: strong empty state before report selection and compact summary after selection.
- Show diagnostic access state clearly.

## Release Gate

Before calling the MVP trustworthy, Corewise must show provenance for every metric and must not present synthetic values as device state.

## Later Ideas

- Menu bar monitor for at-a-glance CPU, memory, swap, and top active process.
- Health score only after real data coverage and a documented formula are stable.
