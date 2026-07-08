# Architecture

## Summary

Corewise is a local SwiftUI macOS app with a single snapshot-oriented data flow. The UI reads a `HealthSnapshot` from a store, renders diagnostic sections, and refreshes live performance samples on a timer.

## Implemented

- App entry: `CorewiseApp` owns a `HealthDashboardStore`.
- Store: `HealthDashboardStore` requests snapshots from `SystemHealthCollecting`.
- Collector protocol: `SystemHealthCollecting.currentSnapshot()` returns a complete `HealthSnapshot`.
- Current collector: `SystemHealthCollector` builds the full product-shaped snapshot without synthetic runtime diagnostics.
- Live helper: `SystemMetricsSampler` provides live CPU split, VM memory fields, process rows, physical footprint when available, and app groups to the collector.
- History helper: `PerformanceHistoryTracker` keeps a short in-memory window for sustained CPU interpretation.
- Battery helper: `BatteryDiagnosticsCollector` provides live safe power-source basics and unavailable/planned health details.
- Manual storage helper: `StorageTargetedScanCollector` scans only a user-selected folder and returns largest real items.
- Manual crash helper: `CrashReportDiagnosticsCollector` parses metadata only from a user-selected reports folder.
- Storage helper: `StorageDiagnosticsCollector` provides read-only live startup-volume capacity only during automatic refresh.
- Startup helper: `StartupDiagnosticsCollector` provides read-only LaunchAgents and LaunchDaemons plist metadata.
- UI: `ContentView` hosts navigation; `DashboardViews` renders section pages, cards, charts, findings, actions, and source notes.

## Data Flow

1. App starts and creates `HealthDashboardStore`.
2. Store asks the configured collector for the current snapshot.
3. `SystemHealthCollector` asks `SystemMetricsSampler` for live performance signals.
4. The collector records short performance history in memory, then combines live battery/performance/storage/startup/thermal signals with planned and unavailable coverage.
5. SwiftUI renders the snapshot into section pages.
6. The store refreshes live data periodically.
7. User-selected storage or crash scans are owned by `HealthDashboardStore` and reapplied to later snapshots. Automatic refresh never starts personal-folder or report scans.

## Collector Boundaries

`SystemMetricsSampler` should stay narrow:

- Read public macOS CPU ticks over a 1 second window.
- Read public VM statistics for used, wired, compressed, free, and swap context.
- Read public process task information for PID, CPU time, thread count, resident memory, path, and user.
- Read `ri_phys_footprint` through `proc_pid_rusage(RUSAGE_INFO_V4)` when macOS returns it.
- Keep individual process rows separate from app-bundle groups.
- Return `nil` or `Unavailable` for unsupported values instead of inventing readings.

`StorageDiagnosticsCollector` should stay privacy-first:

- Read startup volume capacity resource values during automatic refresh.
- Do not enumerate Downloads, Trash, user Library caches, developer folders, or browser caches automatically.
- Leave detailed folder review unavailable or planned until there is an explicit targeted scan flow.

`StorageTargetedScanCollector` should stay explicit:

- Run only after a user folder choice.
- Read file sizes and directory totals without modifying files.
- Omit unreadable items and report their count instead of estimating them.
- Do not persist folder access bookmarks in the first version.

`CrashReportDiagnosticsCollector` should stay narrow:

- Run only after a user folder choice.
- Parse app name, bundle ID, version, date, and repeated counts when present.
- Avoid showing stack traces or report contents in the first version.

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

## Avoided

- A backend data model.
- A persistent local database before there is a clear need.
- Cross-section collectors that blur ownership and make provenance hard to explain.
