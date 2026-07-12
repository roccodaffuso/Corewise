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
| Attention summary | Implemented | Typed supported live metrics through `AttentionSummaryResolver` | High | Conservative attention language only; not a diagnosis or health score. |
| Ranked signal rows | Implemented | Current `HealthSnapshot` performance, storage, battery, thermal, startup, and app-issue roles | Medium | Selects Performance, Storage, and the most relevant System signal; section detail remains authoritative. |
| Health score | Avoided | None | High | Numeric health scoring was removed because incomplete coverage cannot safely support it. |
| Data coverage | Implemented | DataMode signal-family coverage count | High | Describes available data, not device health or row count. |
| Overall attention state | Implemented | Critical/warning ordering across eligible live roles | High | Clear means no urgent supported live signal, not that the Mac is healthy. |
| CPU now | Implemented | `host_statistics` / `HOST_CPU_LOAD_INFO` | Medium | 1 second sample; not a sysmond clone. |
| RAM used now | Implemented | `host_statistics64` / `HOST_VM_INFO64` | Medium | Corewise VM view based on app memory, wired memory, and compressed pages; not a private Activity Monitor clone. |
| Swap used and trend | Implemented | `sysctl vm.swapusage`, `host_statistics64`, `PerformanceHistoryTracker` | Medium | Shows system swap context only; it does not attribute exact swap ownership to processes. |
| System power watts | Unavailable | Safe public API check | High | No reliable whole-system wattage through safe public APIs in this MVP. |
| Main attention area | Implemented | `AttentionSummaryResolver` | High | Uses the highest-ranked supported live signal and one real recommended action. |
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
| Finder available | Implemented | `FileManager` `volumeAvailableCapacity` | High | Lower-level free-space context; Corewise still uses important-usage capacity for practical headroom. |
| Important available | Implemented | `FileManager` `volumeAvailableCapacityForImportantUsage` | High | Best current automatic capacity signal for user-important work and updates. |
| Opportunistic available | Implemented when present | `FileManager` `volumeAvailableCapacityForOpportunisticUsage` | Medium | Some volumes may not expose it; unavailable is shown instead of `0 GB`. |
| Volume name and format | Implemented | `FileManager` `volumeLocalizedName` and `volumeLocalizedFormatDescription` | High | Startup volume only; not a full disk inventory. |
| Volume flags | Implemented | `FileManager` `volumeIsInternal`, `volumeIsLocal`, `volumeIsReadOnly` | Medium | Flags are shown as volume context, not health scoring. |
| Full Disk Access probe | Implemented | Read-only checks against dedicated FDA-protected sentinels | Medium | Never opens Documents, Downloads, Desktop, or scan scopes before consent. A return to Corewise forces a fresh probe; Corewise cannot grant access itself. |
| Full Storage Analysis | Implemented after consent | Full Disk Access plus read-only scans of curated standard scopes | Medium | Optional, local, revocable in System Settings, cancellable, and started explicitly after the initial permission-return flow; normal refresh probes access without enumerating scopes. |
| Folder Scope fallback | Implemented | One `NSOpenPanel` choice plus a security-scoped bookmark | Medium | The approved folder is remembered and reused without another picker; it remains secondary to Full Disk Access and can be forgotten. |
| Storage scan session | Implemented | Approved root/current folder URLs plus scan result | Medium | Full Storage Analysis uses a synthetic approved root; Folder Scope drilldown stays inside the chosen folder. |
| Storage breadcrumbs | Implemented | Derived from approved root and current scan folder | Medium | Used only for navigation inside the approved scope. |
| Storage category breakdown | Implemented after consent | Read-only path rules, bundle/package hints, `UTType` content type, and extension fallback inside approved scopes | Medium | Categories are Corewise's transparent taxonomy, not a System Settings Storage clone. |
| Category examples | Implemented after consent | Largest readable files observed per category | Medium | Shows examples only from approved scopes; unreadable items are counted and omitted instead of estimated. |
| Large folders | Implemented after consent | Read-only scan of approved scopes | Medium | Empty until Full Disk Access or Folder Scope is available. |
| Large files | Implemented after consent | Read-only scan of approved scopes | Medium | Empty until Full Disk Access or Folder Scope is available. |
| Reveal in Finder | Implemented after selection | Finder reveal for a scanned item path | High | Opens Finder only; it does not delete, move, or modify files. |
| Drilldown scan | Implemented after selection | Read-only scan of a folder discovered inside the approved scan session | Medium | Does not scan unrelated folders automatically. |
| Developer data | Implemented after consent | `~/Library/Developer` as part of Full Storage Analysis or Folder Scope | Medium | Read-only size/category classification; no cleanup or DerivedData deletion. |
| Browser caches | Planned | Browser-owned settings or explicit targeted scan | Low | Browser cache folders are not scanned during refresh. |
| Downloads | Implemented after consent | `~/Downloads` as part of Full Storage Analysis or Folder Scope | Medium | Only after Full Disk Access or explicit folder approval; never cleaned automatically. |
| Trash | Avoided | N/A | High | Corewise does not inspect or empty Trash automatically in v1. |
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
| Memory Context | Implemented | Derived from `host_statistics64` VM fields plus Swap Insight | Medium | Plain-language Corewise context only; it is not Activity Monitor's private memory-pressure graph. |
| Swap used | Implemented | `sysctl vm.swapusage` / `xsw_usage` | Medium | Available when macOS returns swap usage. |
| Swap total | Implemented | `sysctl vm.swapusage` / `xsw_usage.xsu_total` | Medium | System-level configured swap, not process-level data. |
| Swap available | Implemented | `sysctl vm.swapusage` / `xsw_usage.xsu_avail` | Medium | System-level remaining swap. |
| Swap encryption state | Implemented | `sysctl vm.swapusage` / `xsw_usage.xsu_encrypted` | Medium | Boolean flag from the current system snapshot. |
| Swapped VM pages | Implemented | `host_statistics64` / `vm_statistics64.swapped_count` | Medium | System-level VM pages; not process ownership. |
| Swap in/out rates | Implemented | Delta of `vm_statistics64.swapins` and `swapouts` over short in-memory history | Medium | Unavailable until at least two valid samples exist; not persisted. |
| Process page-ins | Implemented when present | `proc_pid_rusage(RUSAGE_INFO_V4)` / `ri_pageins` | Medium | Page-ins are pressure context, not proof that the process owns swap. |
| Likely swap contributors | Implemented | Derived from observed memory, RSS/footprint, page-ins, and memory growth | Medium inferred | Ranked as likely memory-pressure contributors only; Corewise does not show exact per-process swap ownership. |
| Uptime | Implemented | `ProcessInfo.systemUptime` | High | Local process uptime signal; not a performance diagnosis by itself. |
| Sustained high CPU | Implemented | In-memory recent process history | Medium | Unavailable until enough samples are collected; not persisted. |
| WindowServer impact | Planned | Process sample plus explanation | Low | Needs careful wording because high usage can be normal. |
| Process-row provenance | Implemented | Table-level live source note | High | Row-level `Live` badges are intentionally omitted in dense tables to preserve readability. |
| Process insights | Implemented | Names, app owners, and paths from live process rows | Medium | Explains common patterns only; does not prove cause or recommend killing processes. |

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
| Startup table | Implemented | Existing plist inventory rows | Medium | UI grouping only; it does not read new folders or modify plist files. |

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
| Crash access empty state | Implemented | Diagnostic permission state from app state | High | Shows no app rows or counts before the user selects reports. |

## Diagnostic Report

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| Summary report | Implemented | Current `HealthSnapshot` through `DiagnosticReportBuilder` | High | Short local clipboard summary with live signals, notable findings, safe next steps, and limits. |
| Markdown report | Implemented | Current `HealthSnapshot` through `DiagnosticReportBuilder` | High | Fuller local clipboard export only; not persisted or uploaded. |
| Notable findings | Implemented | Existing section findings already present in `HealthSnapshot` | Medium | Reuses current findings; does not inspect additional files or logs. |
| Manual next steps | Implemented | Existing safe actions already present in `HealthSnapshot` | Medium | Manual review only; no cleanup or process termination. |
| Top CPU and memory rows | Implemented | Live process rows already present in the snapshot | Medium | Uses the same public API semantics as Performance. |
| Swap insight | Implemented | Current `HealthSnapshot` swap insight | Medium | Includes system swap context and limits; no per-process swap ownership claim. |
| Memory context | Implemented | Current `HealthSnapshot` memory context | Medium | Derived from public VM/swap counters; not Activity Monitor's private pressure graph. |
| Storage scan summary | Implemented after selection | User-selected folder scan results | Medium | Empty when no manual scan exists. |
| Crash summary | Implemented after selection | User-selected report folder metadata | Medium | Counts only; no stack traces or raw report contents. |
| Global score in report | Avoided | None | High | Report explicitly states that Corewise does not calculate a global health score. |

## Menu Bar

| Metric | Status | Source | Confidence | Limit |
| --- | --- | --- | --- | --- |
| CPU total | Implemented | Current `HealthSnapshot` performance CPU reading | Medium | At-a-glance value only; open Corewise for detail. |
| Memory used | Implemented | Current `HealthSnapshot` system memory reading | Medium | Uses Corewise memory semantics, not private Activity Monitor internals. |
| Swap used | Implemented when available | Current `HealthSnapshot` swap reading | Medium | Shows `N/A` when the snapshot does not contain swap. |
| Top CPU rows | Implemented | Current live process rows | Medium | Shows up to three rows from the current snapshot sample; not a persistent monitor. |
| Top memory rows | Implemented | Current live process rows | Medium | Shows up to three rows using observed memory from the existing Performance model. |

## Privacy Notes

- Corewise should not upload diagnostic data.
- Corewise should not read document contents to size files.
- Corewise should not store process histories beyond what is needed for local explanation.
- Corewise should display source and confidence next to every diagnostic claim.
- Storage details are read only after Full Disk Access or Folder Scope approval; crash reports are read only after the user selects a report folder.
- Diagnostic reports copied from Corewise are local Markdown summaries and should not include stack traces or file contents.
