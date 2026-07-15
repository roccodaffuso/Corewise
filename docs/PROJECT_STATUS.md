# Corewise Project Status

Last updated: 2026-07-15

## Public release foundation

- Added a repository-owned Corewise app icon derived from the existing signal glyph, a reproducible Swift generator, and bundle metadata that installs the `.icns` asset with explicit `0.1.0` beta-line version values.
- Rebuilt the public README around the current product truth, privacy boundary, source-build path, and the absence of a published binary.
- Documented the recommended consumer path as a universal Developer ID-signed and notarized DMG on GitHub Releases, with Homebrew Cask following only after the release artifact is stable.
- Added separate preview and release packaging modes. Both build arm64 and x86_64, merge one universal executable, sign with Developer ID and hardened runtime, create and remount a compressed DMG, and write a SHA-256 checksum.
- The publishable `0.1.0 (2)` beta candidate was accepted by Apple under submission `8552a9a6-2342-48ee-82a6-a2261016fc62`; stapling, Gatekeeper, signature, notice, metadata, and checksum verification pass. SHA-256: `90f5f1b16d2507f819468c91eeecab8d490df407ea53cbda27df91bb80ac498b`.
- Added GitHub Actions gates for Swift tests and strict concurrency on clean ARM64 and Intel macOS runners, plus exact-DMG release-candidate validation from a Draft Release without exposing Apple credentials to GitHub.
- Licensed Corewise source under MPL-2.0 with per-file SPDX notices. Development and release bundles now include the complete license and a source-repository notice; Settings links directly to both the public source and license.
- GitHub Actions validated the exact Draft Release DMG on clean ARM64 and Intel runners. Primary-Mac QA passes for installation, first launch, Settings, menu bar, Storage pre-consent, AI Workloads, Light/Dark, 980×680, and 1180×800; details and remaining manual gates are in `docs/BETA_QA_0.1.0.md`.
- Permanent public identity is frozen as Corewise, `dev.corewise.Corewise`, `corewise.dev`, and © 2026 Rocco D’Affuso. The repository/history/assets audit is documented in `docs/PUBLIC_RELEASE_AUDIT.md`.
- The distribution-signed Full Disk Access flow passes grant, relaunch detection, a complete 11-scope read-only analysis without folder prompts, revocation, and return to the access-required state. Remaining beta-publication blockers are clean-account first launch and the outstanding assistive-technology matrix. One external installation and seven public beta days gate stable promotion.

## Focused Diagnostics technical implementation

- Added symptom-led Focused Check flows for Slow, Hot, Battery Drain, Storage Full, and immediate Just Checking.
- The existing refresh is now store-owned and retained; checks continue across navigation and main-window close/reopen without a second sampler.
- Added bounded volatile aggregation, cautious pure resolution, typed battery/thermal readings, and a maximum of three evidence items with one next action.
- Performance now exposes stable app groups, raw-member filtering, typed process explanations, and process/app-group deep links.
- Performance now includes AI Workloads for supported local tools. It aggregates the full process inventory before top-row truncation, separates direct/related/shared resources, and never presents process count as agent count.
- Storage now separates approved-scope classified space from space outside the current result and adds owner/review guidance without cleanup promises.
- Focused results are available in Overview, Quick Actions, menu bar continuity, and local redacted Summary/Markdown reports.
- Verification: 124 tests pass; strict concurrency with warnings-as-errors passes; the English-default localization catalog compiles; signed bundle runtime verification passes; runtime result/deep-link/CPU/Memory smoke tests pass; five-minute idle and Focused Check Time Profiler baselines are recorded.
- Focused Check-exclusive CPU is below the measured budget at 0.0246% average of one core. Malloc high-water evidence identified implicit Full Storage Analysis, not process sampling or Focused Check, as the cause of the approximately 1,416 MB transient peak. Normal refresh no longer starts a broad scan; the repeated release profile peaked at 156 MB and the memory gate passes. See `docs/PERFORMANCE_BASELINE_2026-07-10.md`.
- Release validation still open: external user sessions, a ten-minute Battery check on battery power, final distribution-signature profiling, and the complete screenshot/assistive-technology matrix.

## Corewise Signal System implemented

- Removed the dormant numeric health score and overall status model.
- Added conservative live-only attention resolution, typed roles, ranked Overview signals, and menu bar continuity.
- Replaced the custom two-line sidebar and universal detail scroll with a native grouped sidebar and page-owned scrolling.
- Added `⌘K` Quick Actions, typed routing, redacted initial loading, toolbar refresh, and inline error presentation.
- Rebuilt Performance around a 60-point history, native searchable/sortable process table, stable selection, and inspector.
- Added truthful Storage progress and explicit scan phases; cancellation keeps the last completed result.
- Rebuilt Battery, Thermal, Startup, App Issues, Report, and menu bar with page-specific native layouts.
- Added localization resources, accessibility adaptations, deterministic previews, and focused unit coverage.
- Menu Bar is now content-personalizable without changing collection: users can show supported local AI Workloads, choose CPU/Memory/Swap and process sections, select one to five rows, restore defaults, and open Settings directly from the monitor. Settings now has consistent pane hierarchy, grouped forms, current privacy copy, and a live menu-bar layout preview.
- Corrected the first Signal System visual pass after hands-on feedback: replaced stock system-teal/flat-panel styling with an adaptive graphite palette, Corewise signal glyph, instrument surfaces, stronger page hierarchy, expressive signal rows, framed native tables, and a distinct precision treatment for Performance and Storage.
- Corrected Storage consent UX: Full Disk Access is now the only primary path, app activation forces an automatic recheck, pre-consent probes no longer touch each scan folder, Folder Scope is a remembered one-time fallback, and local bundles use a stable development signature when available.
- Corrected Performance mode semantics: CPU and Memory now derive different process worksets, table columns, sort menus, summary evidence, and inspectors. Direct routing to Memory is respected on first appearance instead of being overwritten by the default preference.
- Previous Signal System verification: 66 Swift Testing tests passed. Current Focused Diagnostics verification: 112 tests pass and strict-concurrency build completes without warnings.

## Summary

Corewise is a local-first macOS diagnostic utility with the production-oriented Signal System shell implemented. It combines live CPU/RAM/process sampling, short history, typed attention resolution, read-only Storage analysis, battery basics, startup inventory, thermal state, manual crash metadata, local reports, Quick Actions, native tables/inspectors, and menu bar continuity. Runtime diagnostics never use synthetic values.

The immediate priority is product trust: Corewise should feel like a diagnostic workflow, not a complete but shallow dashboard. The main workflow direction is Performance first, Full Storage Analysis second, and local Diagnostic Report third.

Baseline checkpoint: `34315cf` (`Checkpoint Corewise diagnostic MVP`).
MVP trust baseline: `996af98` (`Stabilize Corewise trust baseline`).
Real-data acquisition baseline pushed: `db21865` (`Add real data acquisition flows`).
Current state: real-data acquisition started; Performance parity is partially implemented through live process rows, observed memory, RSS, and footprint, but Corewise still does not claim exact Activity Monitor parity.
Product realignment: after last30days research, Corewise is positioned as local diagnostics and explanation, not automatic cleanup or Activity Monitor exact parity.
Remaining last30days work batch completed locally through `fa4e241`: Performance explanations, Storage exploration, Report quality, Startup/App Issues readability, and a light menu bar monitor are implemented. Score remains gated.
Swap Insight baseline: committed as `Add Swap Insight diagnostics`.
Premium redesign baseline: visual foundation, sidebar, shared panels, process tables, storage colors, source notes, and menu bar styling were updated to follow the researched Apple-native redesign direction. No new diagnostic collectors or data claims were added.
Product evolution implementation: Performance explanations, Memory Context, approved-scope storage categories, Report V3 structure, and Overview triage are being implemented from `docs/PRODUCT_EVOLUTION_FROM_RESEARCH.md` without adding mock data, score, cleanup actions, or private APIs.
Full Storage Analysis implementation: Storage now guides the user to optional macOS Full Disk Access, detects likely access, and classifies curated standard scopes locally/read-only. Folder Scope remains a fallback; no raw whole-disk scan, Trash scan, cleanup, upload, or file mutation was added.

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
- Read-only live storage collector for startup volume capacity; Storage now offers `Enable Full Storage Analysis` as the primary path and Folder Scope as fallback.
- Storage volume context now includes Finder-style free space, important/opportunistic capacity where available, volume name, format, local/internal flags, and read-only state without opening personal folders.
- Storage pre-scan UX now leads with useful volume context and Full Disk Access education instead of asking the user to classify folders one by one.
- Full Storage Analysis scans curated standard scopes only after macOS Full Disk Access is likely granted, aggregates categories/largest files/folders/counts, and runs only from an explicit scan trigger or immediately after the one-time permission-return flow. Normal refresh performs an access probe only.
- Folder Scope fallback uses a user-approved folder with breadcrumbs, drilldown into largest folders, parent navigation, largest files, total scanned size, item count, unreadable count, and scan duration.
- Categorized approved-scope storage scan classifies readable space into Applications, Development, Documents, Photos, Video, Music, Archives & Installers, Cache & Temporary, System-like, Other, and Unreadable using transparent local rules.
- Read-only startup plist inventory for accessible LaunchAgents and LaunchDaemons metadata, shown as a compact table with label, kind, executable, startup impact, trust state, and Finder reveal.
- Swap Insight in `Performance > Memory`: system swap used/total/available, trend, swap in/out rates, swapped VM pages, encryption state, and likely memory-pressure contributors. Corewise does not claim exact per-process swap ownership.
- Memory pressure is unavailable until a reliable public parity source is selected.
- Live high-level thermal state from `ProcessInfo.thermalState`.
- User-selected crash report metadata parsing for crash counts and repeated app patterns, with a strong empty state before reports are selected.
- Local Diagnostic Report page with `Summary / Markdown` views, notable findings, manual next steps, source/confidence notes, and clipboard-only copy without stack traces, uploads, file contents, or cleanup actions.
- Native SwiftUI Settings scene has compact General, Privacy & Data, Performance, Report, and Menu Bar tabs, reachable from the macOS Settings command and a footer link below the diagnostic sidebar navigation. Settings controls display/report preferences only and does not change automatic data collection.
- Premium visual system foundations: shared semantic colors, surface roles, page wash, sidebar selection/hover fills, hero/panel/tile/table radii, stable hero and metric heights, table row styling, softer menu bar glass, top-three menu bar process rows, and muted storage used/available colors.
- Product evolution V3 foundations: richer process explanations, derived Memory Context from public VM/swap counters, approved-scope storage category breakdown, and a stronger report structure.
- Read-only, manual-action product stance.

## Planned

- Expand visible provenance coverage as new row types are added.
- Add real health scoring after enough section data is live.
- Refine Full Storage Analysis progress and coverage reporting after real use; cancellation is implemented and no silent scan may leave approved scopes.
- Broaden startup beyond plist inventory only where macOS exposes safe public visibility.
- Add WindowServer interpretation and thermal contributor attribution only through safe sources.
- Keep unavailable wattage clearly marked unless a safe, user-approved source exists.
- Refine menu bar monitor copy and behavior after manual app QA.
- Keep Settings preferences small and local; consider launch-at-login or refresh interval only after separate safety decisions.

## Unavailable

- Modern login items, background items, and privileged helper inventory. Startup code signing is best-effort only when a readable executable path is present.
- Detailed storage categories before Full Disk Access or Folder Scope is approved.
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
- Storage details depend on Full Disk Access or Folder Scope and should not be mistaken for Apple's private System Settings Storage calculation.
- Crash report details depend on a user-selected folder and may miss reports outside that folder.
- Numeric health scoring is intentionally absent. The live-only attention summary must remain conservative and coverage must stay a separate disclosure.
- Report copy is a current-snapshot summary, not a full support bundle or persistent diagnostic archive. It now has a short summary view and a fuller Markdown view, both generated from the same snapshot.
- The implementation is complete; manual screenshot and assistive-technology QA across light/dark and narrow/wide windows remains a release validation task. Runtime enumeration confirms the Overview window now respects the 980-point minimum width (observed at 980×732); macOS screen capture returned a black global frame and denied the per-window image.
- Storage is more informative than the first zero-mock pass; full folder-level insight is driven by optional Full Disk Access, with Folder Scope as a secondary tool.
