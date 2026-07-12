# Architecture

## Focused Diagnostics architecture — 2026-07-10

- `HealthDashboardStore` retains the one existing live refresh task and coordinates `FocusedCheckSession`; it does not rank evidence.
- `FocusedCheckTracker` consumes the same published `HealthSnapshot`, retains at most 300 system points plus 50 app and 50 process accumulators, and deduplicates battery readings by source timestamp.
- `FocusedCheckResolver` is SwiftUI-free and returns a cautious result with one headline, at most three evidence items, one action, and separate coverage text.
- `DashboardFocus` carries process, app-group, storage-category, and storage-path destinations through `AppRouteStore`.
- `AppProcessGroupingResolver` groups by normalized bundle path plus user when possible; raw process rows remain authoritative.
- `StorageCoverageResolver` and `StorageAttributionResolver` keep classified approved-scope space, outside-scope space, inaccessible items, owner class, and review guidance distinct.
- Focused Check state and history are local, volatile, and discarded on quit. No network, persistence, new collector, private API, or destructive action was added.

## Signal System architecture — 2026-07-09

- `HealthSnapshot` has no score or overall-health verdict. It owns an `AttentionSummary` produced by the pure `AttentionSummaryResolver` from typed `DiagnosticMetricRole` values and supported live data only.
- `PerformanceHistoryTracker` exposes at most 60 ordered `PerformanceTimePoint` values while retaining the existing short in-memory diagnostic window.
- Storage collectors emit throttled `StorageScanProgress`; `HealthDashboardStore` publishes `StorageScanPhase`, preserves the last completed session, and discards cancelled partial results.
- `AppRouteStore` is a small MainActor Observation model shared by the main window and menu bar. `HealthDashboardStore` remains the existing ObservableObject collection boundary.
- SwiftUI views are grouped by feature under Overview, Performance, Storage, Diagnostics, Report, and Components. The former monolithic `DashboardViews.swift` has been removed.
- The main scene is a single macOS `Window`; Settings remains a native Settings scene and MenuBarExtra reuses the same snapshot.
- Quick Actions uses typed descriptors and focused scene commands rather than global notifications or singletons.

## Summary

Corewise is a local SwiftUI macOS app with a single snapshot-oriented data flow. The UI reads a `HealthSnapshot` from a store, renders diagnostic sections, and refreshes live performance samples on a timer.

## Implemented

- App entry: `CorewiseApp` owns a `HealthDashboardStore`.
- Store: `HealthDashboardStore` requests snapshots from `SystemHealthCollecting`.
- Store session state: `HealthDashboardStore` owns the session-only storage scan root/current folder and reapplies the latest result to snapshots.
- Collector protocol: `SystemHealthCollecting.currentSnapshot()` returns a complete `HealthSnapshot`.
- Current collector: `SystemHealthCollector` builds the full product-shaped snapshot without synthetic runtime diagnostics.
- Slow snapshot cache: `SlowHealthSnapshotCache` keeps battery, volume, startup-item, and static unavailable app-issue results on source-appropriate cadences instead of rebuilding them on every live tick.
- Live helper: `SystemMetricsSampler` provides live CPU split, VM memory fields, swap reading, process rows, page-ins, observed memory, physical footprint when available, RSS, and app groups to the collector.
- History helper: `PerformanceHistoryTracker` keeps a short in-memory window for sustained CPU interpretation and Swap Insight trend/rate calculations.
- Derived memory helper: `MemoryPressureContext` is built from the current `SystemMemoryReading` and `SwapInsight`; it does not read new APIs and does not claim Activity Monitor memory-pressure parity.
- Battery helper: `BatteryDiagnosticsCollector` provides live safe power-source basics and unavailable/planned health details.
- Storage scan helper: `StorageTargetedScanCollector` scans approved scopes read-only and returns largest real items.
- Full storage helper: `FullStorageAnalysisCollector` probes curated standard scopes for Full Disk Access and aggregates read-only scans across those scopes when access is likely granted.
- Manual crash helper: `CrashReportDiagnosticsCollector` parses metadata only from a user-selected reports folder.
- Storage helper: `StorageDiagnosticsCollector` provides read-only live startup-volume capacity only during automatic refresh.
- Startup helper: `StartupDiagnosticsCollector` provides read-only LaunchAgents and LaunchDaemons plist metadata.
- Report helper: `DiagnosticReportBuilder` renders read-only Summary and Markdown text from the current `HealthSnapshot`.
- Report V3 includes Memory Context, Swap Insight, selected storage scan summaries, crash summaries, and source/confidence notes from the existing snapshot only.
- UI: `ContentView` hosts native navigation, toolbar state, routing, loading, and errors; feature folders render Overview, Performance, Storage, Diagnostics, Report, shared components, and deterministic previews.
- Performance presentation: `ProcessTablePresenter` derives separate worksets from the shared live sample. CPU eligibility requires observed interval activity and exposes CPU-specific sorts; Memory eligibility requires significant observed memory and exposes footprint/RSS/page-in sorts. `PerformanceView` renders different native table schemas and inspectors for the two modes.
- Menu bar: `MenuBarExtra` reads the existing `HealthDashboardStore` snapshot for at-a-glance CPU, memory, swap, and top three CPU/memory process rows.
- Settings: `CorewiseApp` declares a native SwiftUI `Settings` scene. Settings is configuration, not a diagnostic sidebar destination. The dedicated Settings view uses documented `@AppStorage` keys for display/report preferences only.

## Data Flow

1. App starts and creates `HealthDashboardStore`.
2. Store asks the configured collector for the current snapshot.
3. `SystemHealthCollector` asks `SystemMetricsSampler` for live performance signals.
4. The collector records short performance history in memory, derives Swap Insight, tags eligible live metrics, and resolves a conservative cross-section `AttentionSummary`. Coverage remains separate metadata.
5. SwiftUI renders the snapshot into section pages.
6. The store refreshes CPU, memory, and process data periodically; slower battery, volume, startup, and static availability data are reused until their cache cadence expires.
7. Storage access is owned by `HealthDashboardStore`. Before consent, it probes only dedicated Full Disk Access sentinels and never touches Documents, Downloads, Desktop, or scan scopes individually. After opening System Settings, app activation forces a fresh probe and starts the first Full Storage Analysis when access is available. Subsequent broad scans run only from an explicit user action or Storage Focused Check, outside the live refresh path; they support cancellation and keep one remembered Folder Scope as fallback. Normal refresh never enumerates approved scopes. Crash reports are never scanned automatically.
8. The Report page formats the current snapshot locally and can copy either Summary or Markdown text to the clipboard. It does not write files, upload data, or include crash stack traces.
9. The menu bar extra reads the same store snapshot; it does not start a separate collector or persist history.
10. Settings writes local `@AppStorage` preferences. These preferences affect Performance default focus, Report defaults/included summaries, and visible Menu Bar rows; they do not grant Full Disk Access, enable cleanup, or start hidden broad scans.

## Settings Preferences

- `settings.performance.defaultFocus`: initial Performance focus, `cpu` or `memory`.
- `settings.report.defaultFormat`: initial Report view, `summary` or `markdown`.
- `settings.report.includeStorageScan`: whether copied/previewed reports include selected storage scan summaries.
- `settings.report.includeCrashSummary`: whether copied/previewed reports include crash report summaries.
- `settings.menuBar.showCPU`, `settings.menuBar.showMemory`, `settings.menuBar.showSwap`: visible menu bar metric cards.
- `settings.menuBar.showTopCPU`, `settings.menuBar.showTopMemory`: visible menu bar process rows.

Internal storage-consent keys:

- `settings.storage.automaticClassificationBookmark`: security-scoped bookmark for Folder Scope fallback only.
- `settings.storage.automaticClassificationTitle`: display title for the remembered Folder Scope.

These keys do not grant Full Disk Access. Full Disk Access is controlled by macOS System Settings.

The generated local `.app` is signed after resources and `Info.plist` are assembled. The run script prefers an Apple Development identity, supports `COREWISE_CODESIGN_IDENTITY` override, and falls back to ad-hoc signing only when necessary. A stable bundle identifier and designated requirement are required for macOS TCC to recognize Corewise across builds.

## Collector Boundaries

`SystemMetricsSampler` should stay narrow:

- Read public macOS CPU ticks over a 1 second window.
- Read public VM statistics for used, app memory, cached files, wired, compressed, free, and swap context.
- Enumerate processes through `sysctl KERN_PROC_ALL`, with `proc_listallpids` as fallback.
- Read public process task information for PID, CPU time, thread count, resident memory, path, and user.
- Convert process CPU task ticks with `mach_timebase_info` before computing the 1 second CPU delta.
- Read `ri_phys_footprint` and `ri_pageins` through `proc_pid_rusage(RUSAGE_INFO_V4)` when macOS returns them.
- Read `vm.swapusage` through `sysctlbyname` for system swap used, total, available, page size, and encryption state.
- Use observed process memory as the larger public value between footprint and RSS so low footprint values do not hide real process memory.
- Keep individual process rows separate from app-bundle groups.
- Return `nil` or `Unavailable` for unsupported values instead of inventing readings.

`PerformanceHistoryTracker` should keep Swap Insight bounded:

- Keep swap samples in memory only for the short performance window.
- Calculate `rising`, `stable`, `falling`, or `unavailable` from real swap deltas and swap-out rate.
- Rank likely memory-pressure contributors from observed memory, page-ins, and memory growth.
- Never expose exact per-process swap ownership because Corewise does not have a reliable public API for that.

`MemoryPressureContext` should stay derived:

- Use only `SystemMemoryReading` and `SwapInsight`.
- Present plain-language context such as `Quiet`, `Using compression`, `Using swap`, `Swap growing`, or `Review top memory processes`.
- Never call itself Activity Monitor's memory-pressure graph.
- Return unavailable context when the underlying memory reading is not live.

`StorageDiagnosticsCollector` should stay privacy-first:

- Read startup volume capacity and safe volume metadata during automatic refresh: total, used, important/free capacity, Finder-style available capacity, opportunistic capacity when present, localized volume name, format description, local/internal flags, and read-only state.
- Do not enumerate personal folders by default. Detailed classification comes from Full Storage Analysis after macOS Full Disk Access, or from an explicit Folder Scope fallback.
- Never scan `/`, `/System`, `/private`, Trash, or the whole raw disk in v1.

`FullStorageAnalysisCollector` should stay bounded:

- Probe access using dedicated read-only Full Disk Access sentinels, without touching every intended scan scope before consent.
- Scan only curated standard scopes: `/Applications`, `~/Applications`, Desktop, Documents, Downloads, Movies, Music, Pictures, `~/Library/Developer`, `~/Library/Caches`, and `~/Library/Application Support`.
- Reuse `StorageTargetedScanCollector` for each scope and aggregate categories, largest files/folders, unreadable count, file/folder count, duration, and last updated.
- Start broad analysis only after the one-time permission-return flow, an explicit `Start Analysis`/`Scan Again` action, or Storage Focused Check. A recent completed full result may be reused for up to six hours by that explicit Focused Check.
- Cooperatively stop between scopes when the coordinating task is cancelled.

`StorageTargetedScanCollector` should stay explicit:

- Run only after Full Storage Analysis access or a user folder choice.
- Read file sizes and directory totals without modifying files.
- Omit unreadable items and report their count instead of estimating them.
- Persist at most one security-scoped bookmark for Folder Scope fallback after explicit user consent.
- Allow drilldown only inside the current user-selected scan session.
- Keep breadcrumbs derived from the approved root and current folder, not from hidden background enumeration.
- Count files and folders, rank largest files/folders, and derive category breakdown only inside approved scopes.
- Keep only the ten largest file candidates while enumerating instead of retaining and sorting every file record.
- Check cancellation during enumeration and discard cancelled results instead of publishing partial state.
- Keep category breakdown based on transparent path, bundle/package, `UTType`, and extension rules. It is Corewise classification, not Apple's hidden System Settings Storage calculation.

`CrashReportDiagnosticsCollector` should stay narrow:

- Run only after a user folder choice.
- Parse app name, bundle ID, version, date, and repeated counts when present.
- Avoid showing stack traces or report contents in the first version.

`DiagnosticReportBuilder` should stay safe:

- Summarize current snapshot values only; do not run new collectors during export.
- Include top process names, metrics, storage scan summary, startup counts, crash counts, notable findings, manual next steps, and source/confidence notes.
- Include Swap Insight values and the per-process ownership limit.
- Exclude stack traces, raw report bodies, document contents, and automatic remediation.

`StartupDiagnosticsCollector` should stay read-only:

- Read plist metadata from accessible LaunchAgents and LaunchDaemons folders.
- Ignore missing or invalid plist files.
- Keep login items, background items, and privileged helpers as unavailable/planned until safe collectors exist.
- Check code signing only when a launch plist points to a readable executable path.

`SystemHealthCollector` should stay explicit:

- It may preserve page shape while real collectors are built.
- It must use `Planned`, `Unavailable`, or `Avoided` instead of synthetic values when a collector does not exist.
- It should not introduce app-specific examples that can be mistaken for real local diagnosis.

## Planned

- Continue splitting real collectors by section: Battery, Storage, Performance, Startup, Thermal, App Issues.
- Keep `DataMode` on every visible diagnostic value so UI badges do not depend on parsing source text.
- Add per-section collector errors and permission states.
- Add tests around data-mode labeling and non-destructive behavior.
- Consider a menu bar monitor only after the main diagnostic workflows are trustworthy.
- Keep future Settings changes aligned with `docs/SETTINGS_PLAN.md`; no preference may enable automatic cleanup, hidden broad scans, or private data collection.

## Avoided

- A backend data model.
- A persistent local database before there is a clear need.
- Cross-section collectors that blur ownership and make provenance hard to explain.
