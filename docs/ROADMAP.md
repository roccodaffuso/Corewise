# Roadmap

## Phase 1: Trust And Provenance

- Implemented: explicit `Live`, `Mock`, `Planned`, and `Unavailable` data modes in the model.
- Implemented: data-mode badges in metric cards, chart rows, source notes, and diagnostic rows.
- Implemented: CPU/RAM process chart fallbacks removed.
- Keep `DATA_SOURCES.md` synchronized with the UI.

## Phase 2: Storage Read-Only Collector

- Implemented: real total, used, available, and available-percent values.
- Implemented: read-only folder/file sizing for selected safe paths.
- Explain unreadable paths and permissions.
- Never delete, move, or modify files.

## Phase 3: Battery Collector

- Implemented: live charge, power source, and charging state from safe IOKit power-source data.
- Implemented: no-battery state and missing keys render unavailable values instead of placeholders.
- Keep cycle count, maximum capacity, and condition unavailable until a safe documented source is selected.
- Keep service wording tied to macOS-provided state only.

## Phase 4: Performance History

- Keep live CPU/RAM sampling.
- Add short local history for sustained CPU and repeated high process usage.
- Add uptime from `ProcessInfo.systemUptime`.
- Add memory pressure and swap only through safe public signals or mark unavailable.

## Phase 5: Startup Inventory

- Add read-only login item and startup-related inventories where safe.
- Separate user login items, agents, daemons, background items, and privileged helpers.
- Avoid raw deletion suggestions; route actions through System Settings, app settings, package managers, or uninstallers.

## Phase 6: Thermal And App Issues

- Implemented: use `ProcessInfo.thermalState` for safe high-level thermal state.
- Avoid private temperature sensors.
- Read permitted diagnostic reports for crash patterns only when access is available.
- Show diagnostic permission state clearly.

## Release Gate

Before calling the MVP trustworthy, Corewise must show provenance for every metric and must not present mock values as live device state.
