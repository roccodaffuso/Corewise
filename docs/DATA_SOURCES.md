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
| Overall status | Mock | Derived from placeholder score | Medium | Must be relabeled when real scoring exists. |
| CPU now | Implemented | `host_statistics` / `HOST_CPU_LOAD_INFO` | Medium | Short sample window; not identical to Activity Monitor. |
| RAM used now | Implemented | `host_statistics64` / `HOST_VM_INFO64` | Medium | Estimate based on active, wired, and compressed pages. |
| System power watts | Unavailable | Safe public API check | High | No reliable whole-system wattage through safe public APIs in this MVP. |
| Main attention area | Mock | Placeholder prioritization | Medium | Must be recalculated when real collectors land. |

## Battery

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Charge | Mock | IOKit power source APIs where safe | Medium | Current value is not read from the user's Mac. |
| Cycle count | Mock | Documented battery health surface if available | Medium | Availability varies by hardware and macOS version. |
| Maximum capacity | Mock | Documented battery health surface if available | Medium | Do not infer service need without macOS status. |
| Condition | Mock | macOS battery condition when accessible | Medium | Must avoid unsupported hardware claims. |
| Power source | Mock | Power source snapshot | Medium | Should become live before battery page is trusted. |
| Charging state | Mock | Power source snapshot | Medium | Should become live before battery page is trusted. |
| Recent energy impact | Mock | Energy/process correlation if public and safe | Low | Not all Energy tab data is exposed as public API. |
| Battery risk | Mock | Corewise scoring model | Medium | Should stay explanatory, not prescriptive. |

## Storage

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Total, used, available | Mock | `FileManager` volume resource values | High | Current values are placeholders. |
| Available percent | Mock | Derived from real volume values | High | Current value is placeholder. |
| Large folders | Mock | Read-only folder scan | Medium | Must handle permissions and avoid hidden destructive actions. |
| Large files | Mock | Read-only file enumeration | Medium | Must avoid scanning restricted folders without explanation. |
| Developer caches | Mock | Read-only known-path review | Medium | Only show paths that exist and are readable. |
| Browser caches | Mock | Read-only known-path review | Low | Browser-owned cleanup should point to browser settings. |
| Downloads | Mock | Read-only folder size | Medium | User must decide what to keep. |
| Trash | Mock | Read-only folder size | Medium | Corewise must not empty Trash. |
| iOS backups | Mock | Read-only known-path review | Medium | Prefer Finder/device settings for action. |
| Xcode DerivedData, simulators, archives | Mock | Read-only known-path review | Medium | Prefer Xcode for removal actions. |
| Container data | Mock | Read-only known-path review | Low | Must be generic unless a specific installed tool is detected. |

## Performance

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| System CPU now | Implemented | `host_statistics` CPU ticks | Medium | Instant sample, not a long-term trend. |
| System RAM now | Implemented | `host_statistics64` VM stats | Medium | Estimate, not exact Activity Monitor parity. |
| Top CPU processes | Implemented | `proc_listallpids`, `proc_pidinfo(PROC_PIDTASKINFO)` | Medium | Short sample window; inaccessible processes may be omitted. |
| Top RAM processes | Implemented | `proc_pidinfo(PROC_PIDTASKINFO)` resident size | Medium | Resident memory alone is not necessarily bad. |
| App grouping | Implemented | `proc_pidpath` path parsing for `.app` bundles | Medium | Falls back to process names when path is not readable. |
| Memory pressure | Mock | Public VM pressure signal or safe approximation | Medium | Current value is placeholder. |
| Swap used | Mock | VM statistics if exposed safely | Medium | Current value is placeholder. |
| Uptime | Mock | `ProcessInfo.systemUptime` | High | Easy planned live conversion. |
| Sustained high CPU | Mock | Repeated samples over time | Medium | Requires in-app history. |
| WindowServer impact | Mock | Process sample plus explanation | Low | Needs careful wording because high usage can be normal. |

## Startup

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Login items | Mock | System Settings visible items where accessible | Medium | APIs and visibility vary by macOS version. |
| Launch agents | Mock | Read-only plist inventory | Medium | Do not delete plist files. |
| Launch daemons | Mock | Read-only plist inventory | Low | System-wide items require careful explanation. |
| Background items | Mock | Public visibility if available | Low | Some items are intentionally abstracted by macOS. |
| Privileged helpers | Mock | Read-only helper path inventory | Low | Never suggest direct removal. |
| Signed/unsigned | Mock | Code signing checks | Medium | Signed does not mean lightweight. |
| Recently added | Mock | File metadata | Low | Metadata can be misleading. |

## Thermal

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Thermal state | Mock | `ProcessInfo.thermalState` | High | Safe high-level signal; should become live. |
| Low Power Mode | Mock | Public power mode where available | Medium | Availability varies. |
| Temperature sensors | Avoided | Private sensor APIs | High | Not part of the MVP trust model. |
| Likely contributors | Mock | CPU/process correlation | Low | Must be framed as likely, not certain. |

## App Issues

| Metric | Status | Planned source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Diagnostic permission state | Mock | Permission/access check | Medium | Must disclose incomplete access. |
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
