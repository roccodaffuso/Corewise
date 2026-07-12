# Corewise

Corewise is a SwiftUI macOS utility that explains what a Mac is doing in plain language. It is local-first, has no account, no backend, and no tracking.

The current build implements the **Corewise Signal System**: a signal-first, keyboard-friendly macOS workspace that gives one calm answer first and progressively exposes source-level detail. Runtime values are either live, planned, unavailable, or avoided; Corewise never presents synthetic diagnostic data as if it came from the Mac.

It also includes the technical implementation of **Focused Check**: choose a symptom from Overview, let Corewise observe the same supported local snapshot stream, then review a cautious result with bounded evidence, one next action, and explicit limitations. No second sampler, persistent history, network service, cleanup action, or causal claim is introduced.

## Current Truth

Implemented live signals:

- Overview status rail derived only from typed, supported live signals; three ranked groups cover Performance, Storage, and the most relevant System signal.
- No health score or coverage-as-health presentation. Coverage remains a quiet data-quality disclosure.
- Native grouped sidebar, single-window routing, toolbar refresh, inline errors, redacted first-load skeleton, and `⌘K` Quick Actions.
- Data Access overview for live, user-selected, planned, unavailable, and avoided data paths. This supports trust but is not the primary first-viewport content.
- System CPU load and user/system/idle split from macOS CPU ticks.
- System RAM fields from VM statistics: used, app memory, cached files, wired, compressed, and swap.
- Live process table with PID, user, thread count, CPU %, observed memory, RSS, and physical footprint when macOS returns it.
- Swap Insight in `Performance > Memory`: real swap used/total/available, trend, swap in/out rates, swapped VM pages, encryption state, and likely memory-pressure contributors.
- Performance precision console with genuinely distinct CPU and Memory workflows: CPU shows active processes, CPU Now/Time and threads; Memory shows significant holders, observed memory, footprint, RSS and page-ins. Each mode has its own history treatment, sort set, and contextual inspector.
- App grouping derived from real process rows, kept separate from individual process rows.
- Battery charge, power source, and charging state when an internal battery is exposed by macOS power-source data.
- Battery cycle count, maximum capacity, and condition when safe battery registry keys are present.
- Startup volume total, used, available, available percent, Finder-style free space, opportunistic space when macOS exposes it, volume name, format, local/internal flags, and read-only state.
- Startup volume breakdown as used vs available space.
- Full Storage Analysis after one optional macOS Full Disk Access grant: Corewise checks once when the app becomes active after the permission flow, scans curated scopes without per-folder prompts, and later rescans only when requested. It reports real progress without inventing a percentage and keeps the last completed result on cancellation or failure.
- Folder Scope fallback for users who prefer approving one folder instead of Full Disk Access; the selected scope is remembered and is not requested again.
- Short local performance history for sustained CPU interpretation.
- Live swap usage and Swap Insight. Corewise does not show exact per-process swap ownership because macOS does not expose that through reliable public APIs. Memory pressure remains unavailable until Corewise has a reliable public parity source.
- Read-only LaunchAgents and LaunchDaemons plist metadata where readable.
- High-level thermal state from `ProcessInfo.thermalState`.
- User-selected crash report folder parsing for app crash counts and repeated-crash patterns.
- Local Diagnostic Report page that copies Summary or Markdown text without uploads, stack traces, file contents, cleanup, or persistence.
- Compact menu bar continuity surface with the same attention headline, CPU/memory/swap strip, top process rows, and direct routing to Performance.
- Focused Check for Slow, Hot, Battery Drain, Storage Full, and immediate Just Checking, with continuation across navigation/window closure.
- Focused results expose duration, freshness, sources, coverage, direct copy, and typed evidence deep links; Performance carries at most three app groups aggregated across the observation window and preserves the raw process table underneath.
- Stable app-process grouping and typed explanations for helpers, WindowServer, Spotlight, cloud sync, media analysis, Corewise, and unknown processes while preserving raw rows.
- Storage coverage and attribution that distinguish classified approved-scope space, outside-scope space, inaccessible items, and owner/review guidance.
- Local Focused Check Summary/Markdown copy with home-directory redaction.

Planned or unavailable areas:

- A global health score is intentionally not part of the current product. Cross-section prioritization is provided by the conservative live-only `AttentionSummary` model.
- Battery energy impact and risk scoring.
- Whole-disk raw scans, Trash inspection, and unrestricted root/System/private folder classification.
- Modern login items, background items, privileged helpers, and startup code signing checks.
- WindowServer interpretation.
- Thermal contributors beyond high-level public thermal state.

Unavailable by design in the MVP:

- Whole-system wattage through private sensors, sudo-only tools, or unsupported APIs.
- Hidden personal-folder scans without Full Disk Access or explicit folder scope.
- Automatic diagnostic report scans during refresh.
- Automatic deletion, forced app quitting, or destructive optimization.

## Build And Run

```sh
swift build
script/build_and_run.sh
```

The app target is defined in `Package.swift` and requires macOS 14 or newer.

`script/build_and_run.sh` signs the generated app bundle with the first available Apple Development identity so macOS can recognize Corewise consistently across local builds. Set `COREWISE_CODESIGN_IDENTITY` to override the identity; ad-hoc signing is used only when no valid identity exists.

## Performance Semantics

Corewise uses public macOS APIs, not private `sysmond` internals. Process rows are real, but they are not promised to match Monitoraggio Attività bit-for-bit. The primary memory value is `observed memory`: the larger public value between physical footprint and resident memory, with RSS still shown separately. System memory used is derived from app memory, wired memory, and compressed memory; cached files are shown separately because macOS can reclaim much of that memory.

Swap Insight explains the system swap context from `vm.swapusage`, VM statistics, and process page-in/memory signals. It ranks likely memory-pressure contributors, but it never says that a process owns a specific amount of swap.

## Product Workflows

Corewise is organized around three trustworthy workflows:

- Focused Check: start from the symptom, observe supported signals for the appropriate window, and continue into typed Performance or Storage evidence.

- Performance: understand CPU, memory, swap, and which live process rows are active.
- Full Storage Analysis: grant Full Disk Access once in macOS; Corewise rechecks on return, classifies curated standard folders locally without folder-by-folder prompts, and does not repeat broad scans during normal refresh.
- Folder Scope: choose one remembered folder only when the user does not want Full Disk Access; review the largest real files and folders, and reveal items in Finder manually.
- Diagnostic Report: copy a local Summary or Markdown report for review without collecting stack traces or file contents.
- Menu Bar: glance at the same live CPU, memory, swap, and top three CPU/memory process rows without opening a second diagnostic surface.
- Settings: control local display/report preferences; Settings does not enable cleanup, tracking, or broad hidden scans.

## Project Docs

- `PRODUCT.md` defines positioning and design principles.
- `docs/PROJECT_STATUS.md` records the current product state and risks.
- `docs/ARCHITECTURE.md` explains the SwiftUI shell, store, collectors, and data flow.
- `docs/DATA_SOURCES.md` is the source-of-truth matrix for live, planned, unavailable, and avoided signals.
- `docs/SAFETY_PRIVACY.md` defines the local-first and non-destructive rules.
- `docs/DESIGN_SYSTEM.md` captures the intended Apple-native diagnostic UI.
- `docs/PREMIUM_APP_REDESIGN_PLAN.md` records the redesign history and identifies the implemented Signal System as the current direction.
- `docs/ROADMAP.md` orders the next implementation phases.
- `docs/DECISIONS.md` records product and technical decisions.
- `docs/SETTINGS_PLAN.md` defines how Corewise should mature its native macOS Settings window without turning it into another diagnostic page.
- `docs/SWAP_INSIGHT.md` documents swap sources, limits, and allowed wording.
- `docs/PERFORMANCE_BASELINE_2026-07-10.md` records the Focused Check CPU baseline, the corrected Storage allocation attribution, and the passing release memory profile.
- `docs/FOCUSED_DIAGNOSTICS_COMPLETION_AUDIT.md` maps every plan area to current evidence and keeps external/manual release gates explicit.

## Operating Rule

Every diagnostic value must be labeled honestly as `Live`, `Planned`, `Unavailable`, or `Avoided`. If Corewise cannot read a signal through safe public macOS APIs, it should say so and offer a manual review path instead of implying certainty.
