# Data Sources

This file is the source of truth for what Corewise reads today, what is mock, what is planned, and what is avoided.

Statuses:

- `Implemented`: live or functional in the current local app.
- `Mock`: realistic placeholder data used to shape the product.
- `Planned`: intended safe implementation path.
- `Unavailable`: intentionally not read in the MVP.
- `Avoided`: not acceptable for Corewise's trust model.

## Overview

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Health score | Mock | Corewise scoring model placeholder | Medium | Mixes live and mock inputs; not a final diagnostic score. |
| Score confidence | Mock | Corewise scoring model placeholder | High | Currently low because the score includes mock coverage. |
| Overall status | Mock | Derived from placeholder score | Medium | Must be relabeled when real scoring exists. |
| CPU now | Implemented | `host_statistics` / `HOST_CPU_LOAD_INFO` | Medium | Short sample window; not identical to Activity Monitor. |
| RAM used now | Implemented | `host_statistics64` / `HOST_VM_INFO64` | Medium | Estimate based on active, wired, and compressed pages. |
| System power watts | Unavailable | Safe public API check | High | No reliable whole-system wattage through safe public APIs in this MVP. |
| Main attention area | Mock | Placeholder prioritization | Medium | Must be recalculated when real collectors land. |

## Battery

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Battery present | Implemented | IOKit power source APIs | High | If no internal battery is found, Corewise shows unavailable values instead of placeholders. |
| Charge | Implemented | IOKit power source APIs | High | Live only when current/max capacity are present in the power-source snapshot. |
| Power source | Implemented | IOKit power source APIs | High | Live only when power source state is present in the snapshot. |
| Charging state | Implemented | IOKit power source APIs | High | Live only when charging state is present in the snapshot. |
| Cycle count | Unavailable | Documented battery health surface if available later | High | Not collected through the current safe power-source API path. |
| Maximum capacity | Unavailable | Documented battery health surface if available later | High | Not collected through the current safe power-source API path. |
| Condition | Unavailable | macOS battery condition if safely/documentedly accessible later | High | Not collected through the current safe power-source API path. |
| Recent energy impact | Planned | Energy/process correlation if public and safe | Low | Not all Energy tab data is exposed as public API. |
| Battery risk | Mock | Corewise scoring model | Medium | Not scored until health and trend signals are available. |

## Storage

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Total, used, available | Implemented | `FileManager` volume resource values | High | Startup volume only. |
| Available percent | Implemented | Derived from real volume values | High | Startup volume only. |
| Large folders | Unavailable | Explicit targeted scan later | High | Not scanned automatically to avoid privacy prompts. |
| Large files | Unavailable | Explicit targeted scan later | High | Downloads is not scanned during refresh. |
| Developer caches | Planned | Explicit targeted scan later | Medium | Not scanned automatically because these live under user Library. |
| Browser caches | Planned | Browser-owned settings or explicit targeted scan | Low | Browser cache folders are not scanned during refresh. |
| Downloads | Unavailable | Explicit targeted scan later | High | Corewise does not request Downloads access at launch/refresh. |
| Trash | Unavailable | Explicit targeted scan later | High | Corewise must not inspect or empty Trash automatically. |
| iOS backups | Planned | Read-only known-path review | Medium | Prefer Finder/device settings for action. |
| Container data | Planned | Read-only known-path review | Low | Must be generic unless a specific installed tool is detected. |

## Performance

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| System CPU now | Implemented | `host_statistics` CPU ticks | Medium | Instant sample, not a long-term trend. |
| System RAM now | Implemented | `host_statistics64` VM stats | Medium | Estimate, not exact Activity Monitor parity. |
| Top CPU processes | Implemented | `proc_listallpids`, `proc_pidinfo(PROC_PIDTASKINFO)` | Medium | Short sample window; inaccessible processes may be omitted. |
| Top RAM processes | Implemented | `proc_pidinfo(PROC_PIDTASKINFO)` resident size | Medium | Resident memory alone is not necessarily bad. |
| App grouping | Implemented | `proc_pidpath` path parsing for `.app` bundles | Medium | Falls back to process names when path is not readable. |
| Memory pressure | Mock | Public VM pressure signal or safe approximation | Medium | Current value is placeholder and labeled mock. |
| Swap used | Mock | VM statistics if exposed safely | Medium | Current value is placeholder. |
| Uptime | Implemented | `ProcessInfo.systemUptime` | High | Local process uptime signal; not a performance diagnosis by itself. |
| Sustained high CPU | Implemented | In-memory recent process history | Medium | Unavailable until enough samples are collected; not persisted. |
| WindowServer impact | Mock | Process sample plus explanation | Low | Needs careful wording because high usage can be normal. |

## Startup

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Login items | Unavailable | System Settings visible items where accessible | Medium | Not collected by the plist inventory. |
| Launch agents | Implemented | Read-only plist inventory | Medium | Reads accessible `~/Library/LaunchAgents` and `/Library/LaunchAgents` metadata only. |
| Launch daemons | Implemented | Read-only plist inventory | Medium | Reads accessible `/Library/LaunchDaemons` metadata only. |
| Background items | Planned | Public visibility if available | Low | Some items are intentionally abstracted by macOS. |
| Privileged helpers | Planned | Read-only helper path inventory | Low | Never suggest direct removal. |
| Signed/unsigned | Planned | Code signing checks | Medium | Current rows show `Not checked`. |
| Recently added | Implemented | Plist modification date | Low | Metadata can be misleading and is only a clue. |

## Thermal

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Thermal state | Implemented | `ProcessInfo.thermalState` | High | Safe high-level signal, not a temperature reading. |
| Low Power Mode | Planned | Public power mode where available | Medium | Availability varies. |
| Temperature sensors | Avoided | Private sensor APIs | High | Not part of the MVP trust model. |
| Likely contributors | Planned | CPU/process correlation | Low | Requires sustained live process history. |

## App Issues

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Diagnostic permission state | Unavailable | Permission/access check | Medium | Not implemented; must disclose incomplete access. |
| Crashes last 7 days | Mock | Permitted diagnostic reports | Medium | Access may be limited. |
| Crashes last 30 days | Mock | Permitted diagnostic reports | Medium | Access may be limited. |
| Last crash date | Mock | Diagnostic report metadata | Medium | Must avoid reading unnecessary content. |
| Bundle ID and version | Mock | Diagnostic report metadata or app bundle metadata | Medium | May be unavailable for some reports. |
| Repeated crash flag | Mock | Derived from crash counts | Medium | Should only highlight repeated patterns. |

## Privacy Notes

- Corewise should not upload diagnostic data.
- Corewise should not read document contents to size files.
- Corewise should not store process histories beyond what is needed for local explanation.
- Corewise should display source and confidence next to every diagnostic claim.
