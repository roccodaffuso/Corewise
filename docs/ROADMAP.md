# Roadmap

## Public release foundation

- [x] Add a reproducible repository-owned app icon and include it in the generated application bundle.
- [x] Replace the prototype README with a public-facing product, privacy, build, and contribution overview.
- [x] Document the recommended DMG, Homebrew, source-build, and Mac App Store distribution paths.
- [x] License Corewise source under MPL-2.0 with per-file SPDX notices and bundled source/license disclosure.
- [x] Freeze the permanent bundle identifier, versioning policy, copyright metadata, and trademark boundary.
- [x] Add universal Developer ID-signed, hardened-runtime, timestamped DMG packaging with checksum and mounted-artifact verification.
- [x] Validate the `notarytool` Keychain profile, Apple acceptance, zero-issue log, stapling, and local Gatekeeper assessment in public release mode.
- [x] Validate the exact `0.1.0 (2)` Draft Release artifact and checksum on clean GitHub-hosted ARM64 and Intel runners.
- [x] Replace the superseded beta.1 candidate with notarized `0.1.0 (3)` beta.2 and repeat exact-artifact ARM64, Intel, Gatekeeper, and Quick Actions keyboard validation.
- [x] Validate primary-Mac installation, first launch, menu bar, Settings, Storage pre-consent, AI Workloads, Light/Dark, 980×680, and 1180×800.
- [x] Validate Full Disk Access grant, relaunch detection, complete read-only scan without folder prompts, revocation, and access-required return on the distribution-signed app.
- [x] Publish `v0.1.0-beta.2` with the exact notarized DMG and checksum.
- [x] Deploy the static site through GitHub Pages and configure `corewise.dev` as its custom domain.
- [ ] Enable HTTPS after GitHub finishes certificate issuance, then verify the apex and `www` hostnames. The Hostinger-to-GitHub Pages DNS cutover is complete and propagated.
- [ ] Validate the distribution artifact on a clean account and through at least one external installation before publishing the stable binary.

## Implemented: Focused Diagnostics technical foundation

- [x] Add symptom-led Focused Check lifecycle and cautious pure resolver.
- [x] Reuse one store-owned refresh loop with bounded volatile aggregation.
- [x] Complete Storage checks from real scans and disclose approved-scope coverage.
- [x] Add stable app grouping, typed process interpretation, and evidence deep links.
- [x] Add Focused results to Overview, reports, Quick Actions, and menu bar continuity.
- [x] Add strict-concurrency-safe store integration, deterministic fixtures, and focused regression tests.
- [ ] Run 8-12 external trigger-based sessions before treating the workflow as product-validated.
- [x] Record five-minute idle/active Instruments baselines on a representative Mac.
- [x] Remove implicit Full Storage Analysis from normal refresh and reduce the measured release physical-footprint peak from approximately 1,416 MB to 156 MB, below the 700 MB gate.
- [ ] Complete light/dark, size, keyboard, VoiceOver, Reduce Motion, Reduce Transparency, and Increase Contrast release QA.

## Completed: Signal System production redesign

- [x] Remove numeric health scoring and implement typed live-only attention resolution.
- [x] Replace card-grid Overview with status rail, ranked signals, resource rows, and quiet coverage disclosure.
- [x] Adopt native grouped sidebar, typed routing, single-window shell, toolbar refresh, and Quick Actions.
- [x] Rebuild Performance with short history, native Table, search/sort, and inspector.
- [x] Add truthful Storage progress, explicit scan phases, result modes, breadcrumbs, and Finder reveal.
- [x] Rebuild Battery, Thermal, Startup, App Issues, Report, Settings continuity, and menu bar hierarchy.
- [x] Add localization catalog, accessibility adaptations, deterministic previews, and resolver/presenter/progress tests.

## Next validation work

- [ ] Finish the documented screenshot matrix; Light/Dark at 980×680 and Dark at 1180×800 pass, while 1440×900 remains.
- [ ] Complete keyboard-only and Accessibility Inspector QA with Reduce Motion, Reduce Transparency, and Increase Contrast.
- [x] Measure sustained two-second refresh CPU with five-minute idle and Focused Check Time Profiler recordings.
- [ ] Measure energy impact and a ten-minute Battery check while physically running on battery power.
- [ ] Use real feedback to refine density; do not add cards, telemetry, private sources, or destructive controls speculatively.

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
- Implemented: safe startup-volume context for Finder-style free space, important/opportunistic availability, volume name, format, local/internal flags, and read-only state.
- Implemented: automatic refresh reads startup-volume capacity and probes access only; broad analysis starts from an explicit action or immediately after the one-time permission-return flow.
- Implemented: Full Disk Access probe and `Enable Full Storage Analysis` flow for optional broad local storage classification.
- Implemented: Full Storage Analysis scans curated standard scopes only; it does not scan `/`, `/System`, `/private`, Trash, or the raw whole disk.
- Implemented: explicit user-selected folder scan with largest folders/files, unreadable count, and scan duration.
- Implemented: Folder Scope fallback for users who prefer approving one folder instead of Full Disk Access.
- Implemented: approved storage scans include file count, folder count, largest examples, and category breakdown for Applications, Development, Documents, Photos, Video, Music, Archives & Installers, Cache & Temporary, System-like, Other, and Unreadable.
- Implemented: scanned storage items can be revealed in Finder without deletion or file mutation.
- Implemented: large Full Storage Analysis progress/cancel behavior, bounded per-item allocation, and explicit classified/outside-scope/inaccessible coverage reporting.
- Never delete, move, or modify files.

## Phase 3: Battery Collector

- Implemented: live charge, power source, and charging state from safe IOKit power-source data.
- Implemented: no-battery state and missing keys render unavailable values instead of placeholders.
- Implemented when present: cycle count, maximum capacity, and condition from safe IOKit battery registry keys.
- Keep service wording tied to macOS-provided state only.

## Phase 4: Performance History

- Implemented: live CPU split, VM memory fields, and dense process rows.
- Implemented: Performance is the main diagnostic page and is organized around "what is slowing my Mac right now".
- Implemented: Performance explanations cover common live process patterns such as helpers/renderers, Electron-style apps, WindowServer, Spotlight, file provider/iCloud sync, media services, and Corewise itself.
- Implemented: Memory Context derives plain-language memory state from public VM and swap counters. It is not Activity Monitor's private memory-pressure graph.
- Implemented: process physical footprint through `proc_pid_rusage(RUSAGE_INFO_V4)` when macOS returns it.
- Implemented: observed process memory uses the larger public value between footprint and RSS, with RSS still visible.
- Implemented: app groups are derived from process rows and kept separate from the process table.
- Implemented: AI Workloads separates app footprint, related local work, and shared hosts; exposes a tiered registry, native table/inspector, typed routing, and a bounded ten-minute Observe AI Session.
- Implemented: short local in-memory history for sustained CPU and repeated high process usage.
- Implemented: uptime from `ProcessInfo.systemUptime`.
- Implemented: swap usage, total, available, encryption state, swapped VM pages, trend, and swap in/out rates from safe local VM signals.
- Implemented: likely memory-pressure contributors based on live process memory, page-ins, and memory growth, without claiming exact per-process swap ownership.
- Unavailable: memory pressure until a reliable public parity source is selected.
- Keep WindowServer interpretation planned until there is enough context.

## Phase 4.5: Diagnostic Report

- Implemented: local Summary and Markdown report builder from the current snapshot.
- Implemented: Report page copies Summary or Markdown to the clipboard only.
- Implemented: notable findings, manual next steps, and source/confidence notes derived from existing snapshot data.
- Implemented: report excludes stack traces, raw crash contents, file contents, uploads, and cleanup actions.
- Implemented: report includes Swap Insight with real values and source limits.
- Implemented: report includes Memory Context and a clearer `Memory And Swap` section.
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

## Phase 7: Menu Bar Monitor

- Implemented: customizable menu bar monitor for at-a-glance CPU, memory, swap, supported local AI workloads, bounded CPU/memory rows, Focused Check, Settings, and Open Corewise.
- Planned: refine menu bar behavior after manual QA on compact displays and with five-row density.

## Phase 7.5: Settings

- Implemented: native SwiftUI Settings window with consistent pane hierarchy, grouped forms, General, Privacy & Data, Performance, Report, and Menu Bar tabs.
- Implemented: documented `@AppStorage` keys for Performance default focus including AI Workloads, Report defaults, optional report summaries, menu bar visibility, and bounded list density.
- Avoid: adding Settings as a main diagnostic sidebar destination.
- Avoid: any setting that enables automatic cleanup, hidden broad background scans, private APIs, sudo-only data collection, process killing, accounts, backend services, telemetry, or tracking.

## Phase 8: Premium Visual System

- Implemented: dynamic semantic tokens, solid tonal content, native sidebar, native tables, inspectors, Quick Actions, and menu bar continuity.
- Implemented: ranked signal Overview with quiet coverage disclosure and no health score.
- Implemented: truthful Storage progress and page-specific Battery, Thermal, Startup, App Issues, and Report layouts.
- Implemented: accessibility adaptations, string catalog, and deterministic previews.
- Release validation: manual screenshot and assistive-technology matrix remains open above.

## Later ideas

- Add new diagnostics only when they have a safe public source and a specific user question; do not reintroduce numeric health scoring by default.
