# Architecture

## Summary

Corewise is a local SwiftUI macOS app with a single snapshot-oriented data flow. The UI reads a `HealthSnapshot` from a store, renders diagnostic sections, and refreshes live performance samples on a timer.

## Implemented

- App entry: `CorewiseApp` owns a `HealthDashboardStore`.
- Store: `HealthDashboardStore` requests snapshots from `SystemHealthCollecting`.
- Collector protocol: `SystemHealthCollecting.currentSnapshot()` returns a complete `HealthSnapshot`.
- Current collector: `MockSystemHealthCollector` builds the full product-shaped snapshot.
- Live helper: `SystemMetricsSampler` provides live CPU, RAM, and process samples to the mock collector.
- History helper: `PerformanceHistoryTracker` keeps a short in-memory window for sustained CPU interpretation.
- Battery helper: `BatteryDiagnosticsCollector` provides live safe power-source basics and unavailable/planned health details.
- Storage helper: `StorageDiagnosticsCollector` provides read-only live startup-volume capacity only during automatic refresh.
- Startup helper: `StartupDiagnosticsCollector` provides read-only LaunchAgents and LaunchDaemons plist metadata.
- UI: `ContentView` hosts navigation; `DashboardViews` renders section pages, cards, charts, findings, actions, and source notes.

## Data Flow

1. App starts and creates `HealthDashboardStore`.
2. Store asks the configured collector for the current snapshot.
3. `MockSystemHealthCollector` asks `SystemMetricsSampler` for live performance signals.
4. The collector records short performance history in memory, then combines live battery/performance/storage/startup/thermal signals with remaining mock diagnostic coverage.
5. SwiftUI renders the snapshot into section pages.
6. The store refreshes live data periodically.

## Collector Boundaries

`SystemMetricsSampler` should stay narrow:

- Read public macOS CPU ticks.
- Read public VM statistics.
- Read public process task information.
- Group helper processes by app bundle path when available.
- Return `nil` or `Unavailable` for unsupported values instead of inventing readings.

`StorageDiagnosticsCollector` should stay privacy-first:

- Read startup volume capacity resource values during automatic refresh.
- Do not enumerate Downloads, Trash, user Library caches, developer folders, or browser caches automatically.
- Leave detailed folder review unavailable or planned until there is an explicit targeted scan flow.

`StartupDiagnosticsCollector` should stay read-only:

- Read plist metadata from accessible LaunchAgents and LaunchDaemons folders.
- Ignore missing or invalid plist files.
- Keep login items, background items, privileged helpers, and code signing as unavailable/planned until safe collectors exist.

`MockSystemHealthCollector` should be temporary:

- It may preserve UI shape while real collectors are built.
- It must label mock values through source/confidence metadata.
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
