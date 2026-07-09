# Swap Insight

## Summary

Swap Insight explains why system swap may matter without pretending Corewise can inspect exact per-process swap ownership. The product answer to "what is in swap?" is: Corewise can show real system swap state, real swap movement, and likely memory-pressure contributors from public local signals.

## Implemented

- `SwapReading` stores system swap used, total, available, page size, encryption state, swapped VM pages, swap-ins, swap-outs, source, confidence, and last updated.
- `SystemMemoryReading.swap` holds the full reading. `swapUsedBytes` remains a computed compatibility value.
- `ProcessObservation.pageIns` stores process page-ins when `proc_pid_rusage` returns them.
- `PerformanceHistoryTracker` keeps only the recent in-memory window and derives trend plus rates.
- `Performance > Memory` shows Swap Insight above the memory pressure list.
- Diagnostic Report includes Swap Insight and the source limit.

## Sources

- `sysctlbyname("vm.swapusage")` / `xsw_usage`: system swap total, available, used, page size, and encrypted flag.
- `host_statistics64(HOST_VM_INFO64)` / `vm_statistics64`: `swapins`, `swapouts`, `swapped_count`, compressor/internal/external page context.
- `proc_pid_rusage(RUSAGE_INFO_V4)` / `rusage_info_v4`: `ri_pageins` and `ri_phys_footprint` when macOS returns them.
- `proc_pidinfo(PROC_PIDTASKINFO)`: resident memory and task timing context.

Reference surfaces: Apple `sysctl(3)` and public XNU headers for `sysctl.h`, `vm_statistics.h`, `resource.h`, and `task_info.h`.

## Trend Rules

- `Rising`: swap used grows by at least 256 MB in the recent window, or swap-out rate is above 8 MB/min.
- `Falling`: swap used falls by at least 256 MB.
- `Stable`: change stays below the threshold.
- `Unavailable`: fewer than two valid swap samples or missing swap data.

Rates are calculated from the first and last valid samples in the short in-memory window. History is not persisted.

## Contributors

Likely contributors are ranked from live process observations:

- observed memory, defined as the larger public value between footprint and RSS;
- resident memory;
- physical footprint when available;
- page-ins;
- memory growth across the recent window.

These rows are useful context, not ownership. A high-memory process with page-ins and growth may be contributing to memory pressure, but Corewise does not know that a specific amount of its memory lives in swap.

## Allowed Wording

- "Swap Insight"
- "System swap used"
- "Swap in/out rate"
- "Likely memory pressure contributors"
- "macOS does not expose exact per-process swap ownership through public APIs."
- "These rows show likely contributors based on live memory signals."

## Avoided Wording

- "This process has X GB in swap."
- "Swap contents by app."
- "Exact swap owner."
- "Corewise can see exact swapped memory by process."

## Privacy And Safety

Swap Insight does not read file contents, does not inspect swap files, does not use `sudo`, does not use private sensor APIs, and does not kill or modify processes. It is a read-only local diagnostic based on public macOS APIs.
