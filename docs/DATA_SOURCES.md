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
| Live Signals header | Implemented | DataMode signal-family coverage plus live section signals | High | Shows coverage and real local signals; it is not a health score and does not count individual process rows. |
| Health score | Planned | Corewise scoring model | High | Not calculated until scoring has enough live inputs. |
| Score confidence | Implemented | DataMode signal-family coverage count | High | Describes coverage, not device health or row count. |
| Overall status | Planned | Corewise scoring model | High | Overview leads with coverage and live signals until real scoring exists. |
| CPU now | Implemented | `host_statistics` / `HOST_CPU_LOAD_INFO` | Medium | 1 second sample; not a sysmond clone. |
| RAM used now | Implemented | `host_statistics64` / `HOST_VM_INFO64` | Medium | Corewise VM view based on app memory, wired memory, and compressed pages; not a private Activity Monitor clone. |
| System power watts | Unavailable | Safe public API check | High | No reliable whole-system wattage through safe public APIs in this MVP. |
| Main attention area | Unavailable | Corewise scoring model | High | Cross-section prioritization is not implemented. |
| Data access capabilities | Implemented | Static capability matrix plus scan state | High | Explains access state; it is not a device-health signal. |

## Battery

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Battery present | Implemented | IOKit power source APIs | High | If no internal battery is found, Corewise shows unavailable values instead of placeholders. |
| Charge | Implemented | IOKit power source APIs | High | Live only when current/max capacity are present in the power-source snapshot. |
| Power source | Implemented | IOKit power source APIs | High | Live only when power source state is present in the snapshot. |
| Charging state | Implemented | IOKit power source APIs | High | Live only when charging state is present in the snapshot. |
| Cycle count | Implemented when present | IOKit battery registry | Medium | Shown only when safe registry keys are present; otherwise unavailable. |
| Maximum capacity | Implemented when present | IOKit battery registry `AppleRawMaxCapacity` or `NominalChargeCapacity` over `DesignCapacity` | Medium | `MaxCapacity` can be a 0-100 power-source scale and is not divided by `DesignCapacity` unless the ratio is plausible. |
| Condition | Implemented when present | IOKit battery registry | Medium | Shown only when a condition string is present; Corewise does not infer service state. |
| Recent energy impact | Planned | Energy/process correlation if public and safe | Low | Not all Energy tab data is exposed as public API. |
| Battery risk | Planned | Corewise scoring model | Medium | Not scored until health and trend signals are available. |

## Storage

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Total, used, available | Implemented | `FileManager` volume resource values | High | Startup volume only. |
| Available percent | Implemented | Derived from real volume values | High | Startup volume only. |
| User-selected folder scan | Implemented | `NSOpenPanel` folder choice plus read-only size scan | Medium | Runs only after user action; no bookmark is persisted in this version. |
| Large folders | Implemented after selection | Read-only scan of chosen folder | Medium | Empty until the user chooses a folder. |
| Large files | Implemented after selection | Read-only scan of chosen folder | Medium | Empty until the user chooses a folder. |
| Developer caches | Planned | Explicit targeted scan later | Medium | Not scanned automatically because these live under user Library. |
| Browser caches | Planned | Browser-owned settings or explicit targeted scan | Low | Browser cache folders are not scanned during refresh. |
| Downloads | Unavailable | Explicit targeted scan later | High | Corewise does not request Downloads access at launch/refresh. |
| Trash | Unavailable | Explicit targeted scan later | High | Corewise must not inspect or empty Trash automatically. |
| iOS backups | Planned | Read-only known-path review | Medium | Prefer Finder/device settings for action. |
| Container data | Planned | Read-only known-path review | Low | Must be generic unless a specific installed tool is detected. |

## Performance

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| System CPU now | Implemented | `host_statistics` CPU ticks | Medium | 1 second sample with user/system/idle split. |
| System RAM now | Implemented | `host_statistics64` VM stats | Medium | Shows Corewise VM view: app memory, cached files, wired, compressed, and swap. |
| Process table | Implemented | `sysctl KERN_PROC_ALL`, fallback `proc_listallpids`, `proc_pidinfo(PROC_PIDTASKINFO)` | Medium | Inaccessible processes may be omitted, but enumeration uses the BSD process list first to avoid missing renderer/helper processes. |
| Process CPU | Implemented | Delta of `pti_total_user + pti_total_system`, converted with `mach_timebase_info` | Medium | 1 second sample; processes that deny task info, such as some system-owned services, may be omitted rather than guessed. |
| Process observed memory | Implemented | Derived from public process memory fields | Medium | Primary UI value is the larger public value between physical footprint and resident memory to avoid under-reporting. |
| Process memory footprint | Implemented when present | `proc_pid_rusage(RUSAGE_INFO_V4)` / `ri_phys_footprint` | Medium | Public footprint can be lower than resident memory and does not promise exact Monitoraggio Attività parity. |
| Process resident memory | Implemented | `proc_pidinfo(PROC_PIDTASKINFO)` resident size | Medium | Kept separate from footprint. |
| Process identity | Implemented | `proc_pidpath`, `proc_name`, short BSD info | Medium | Provides path, app bundle, PID, user, and thread count where readable. |
| App grouping | Implemented | Derived from live process rows and `.app` bundle paths | Medium | Separate from individual process rows so helper aggregation is explicit. |
| Memory pressure | Unavailable | No selected public parity source | High | Corewise does not show an estimated pressure value as live. |
| Swap used | Implemented | `sysctl vm.swapusage` | Medium | Available when macOS returns swap usage. |
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
| Signed/unsigned | Implemented when path readable | Security framework static code check | Medium | Rows remain `Not checked` when the executable path is missing or unreadable. |
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
| Diagnostic permission state | Implemented after selection | User-selected report folder | Medium | Corewise does not scan reports automatically. |
| Crashes last 7 days | Implemented after selection | Crash report metadata | Medium | Counts only readable reports in the chosen folder. |
| Crashes last 30 days | Implemented after selection | Crash report metadata | Medium | Counts only readable reports in the chosen folder. |
| Last crash date | Implemented after selection | Crash report metadata or file date fallback | Medium | Stack traces are not shown in the first version. |
| Bundle ID and version | Implemented when present | Crash report metadata | Medium | Missing fields are shown as unavailable. |
| Repeated crash flag | Implemented after selection | Derived from real crash counts | Medium | Highlights repeated patterns from selected reports only. |

## Privacy Notes

- Corewise should not upload diagnostic data.
- Corewise should not read document contents to size files.
- Corewise should not store process histories beyond what is needed for local explanation.
- Corewise should display source and confidence next to every diagnostic claim.
- Storage folders and crash reports are read only after user-selected folder scans.
