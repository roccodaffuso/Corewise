# Data Sources

This file is the source of truth for what Corewise reads today, what is planned, what is unavailable, and what is avoided.

Statuses:

- `Implemented`: live or functional in the current local app.
- `Planned`: intended safe implementation path.
- `Unavailable`: intentionally not read in the MVP.
- `Avoided`: not acceptable for Corewise's trust model.

## Overview

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Health score | Planned | Corewise scoring model | High | Not calculated until scoring has enough live inputs. |
| Score confidence | Implemented | DataMode coverage count | High | Describes coverage, not device health. |
| Overall status | Planned | Corewise scoring model | High | UI shows Not Scored Yet until real scoring exists. |
| CPU now | Implemented | `host_statistics` / `HOST_CPU_LOAD_INFO` | Medium | Short sample window; not identical to Activity Monitor. |
| RAM used now | Implemented | `host_statistics64` / `HOST_VM_INFO64` | Medium | Estimate based on active, wired, and compressed pages. |
| System power watts | Unavailable | Safe public API check | High | No reliable whole-system wattage through safe public APIs in this MVP. |
| Main attention area | Unavailable | Corewise scoring model | High | Cross-section prioritization is not implemented. |

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
| Battery risk | Planned | Corewise scoring model | Medium | Not scored until health and trend signals are available. |

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
| Memory pressure | Unavailable | Public VM pressure signal or safe approximation | Medium | Not displayed until a safe source is implemented. |
| Swap used | Planned | VM statistics if exposed safely | Medium | Not displayed until a safe source is implemented. |
| Uptime | Implemented | `ProcessInfo.systemUptime` | High | Local process uptime signal; not a performance diagnosis by itself. |
| Sustained high CPU | Implemented | In-memory recent process history | Medium | Unavailable until enough samples are collected; not persisted. |
| WindowServer impact | Planned | Process sample plus explanation | Low | Needs careful wording because high usage can be normal. |

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
| Crashes last 7 days | Unavailable | Permitted diagnostic reports | Medium | Access may be limited; Corewise does not invent counts. |
| Crashes last 30 days | Unavailable | Permitted diagnostic reports | Medium | Access may be limited; Corewise does not invent counts. |
| Last crash date | Unavailable | Diagnostic report metadata | Medium | Must avoid reading unnecessary content. |
| Bundle ID and version | Unavailable | Diagnostic report metadata or app bundle metadata | Medium | May be unavailable for some reports. |
| Repeated crash flag | Planned | Derived from real crash counts | Medium | Should only highlight repeated patterns from real reports. |

## Privacy Notes

- Corewise should not upload diagnostic data.
- Corewise should not read document contents to size files.
- Corewise should not store process histories beyond what is needed for local explanation.
- Corewise should display source and confidence next to every diagnostic claim.
