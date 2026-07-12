# Corewise Performance Baseline — 2026-07-10

## AI Workloads follow-up — 2026-07-12

AI Workloads reuses the existing process inventory and one-second CPU window. Three isolated live-snapshot test runs on the final implementation completed in 1.580, 1.509, and 1.489 seconds; the 1.509-second median is below the previously observed 1.585-second baseline run. Classification uses one PID map with memoized parent-chain ownership and cached signing identity, so no second sampler or refresh task was added.

Status: CPU and memory gates passed for the implemented Focused Diagnostics path. External user validation and the full manual accessibility/visual matrix remain open.

## Environment

- MacBook Air, macOS 26.5.1 (25F80).
- Instruments 16.0 (17F42), Time Profiler.
- Five-minute idle and Focused Check workflow recordings attached to the signed local bundle.
- Additional `footprint`, `heap`, and full malloc stack-history sampling on debug and `-c release` builds.
- The release memory run used a temporary ad-hoc-signed bundle and did not modify `dist/Corewise.app`.

## CPU results

| Five-minute sample | Sampled CPU time | Average of one core |
| --- | ---: | ---: |
| Idle Overview | 41.142 s | 13.668% |
| Focused Check workflow | 20.341 s | 6.758% |

The total difference is not attributed to Focused Check because the two runs contain different view states and normal system-load variation. Feature-exclusive symbols are the safer attribution:

| Symbol family | CPU time | Average of one core |
| --- | ---: | ---: |
| Any `FocusedCheck` symbol during workflow | 0.074 s | 0.0246% |
| `FocusedCheckResultView.body` | 0.036 s | 0.0120% |
| Any `FocusedCheck` symbol while idle | 0.138 s | 0.0458% |

The dominant inclusive work remains the pre-existing process sampler:

- `SystemMetricsSampler.sampleProcesses`: 2.763 s in the workflow run.
- `SystemMetricsSampler.processStats`: 1.668 s.
- `SystemMetricsSampler.processPath`: 0.668 s.
- `HealthDashboardStore.refresh`: 1.198 s.

Conclusion: the Focused Check tracker, resolver, and result surface are not CPU hotspots. Process enumeration remains the main CPU optimization target.

## Memory results

The first release baseline reached an approximately 1,416 MB transient physical-footprint peak during the first 90-120 seconds. The footprint later returned to approximately 397 MB and then 255 MB. This was initially attributed to the live process acquisition path because the curve appeared on multiple pages.

Full malloc stack history disproved that attribution. At the recorded high-water mark, the dominant allocation path was:

- `HealthDashboardStore.scanFullStorageAnalysisIfNeeded(force:)`: approximately 236 MB live in the stack-logged run;
- `FullStorageAnalysisCollector.scan`: approximately 235 MB;
- `StorageTargetedScanCollector.scan`: approximately 138 MB;
- repeated path normalization/top-folder classification: approximately 96 MB.

The process collector accounted for only a few hundred kilobytes in the same high-water sample. The real problem was that a remembered or already-authorized Full Storage Analysis could start implicitly during the first normal refresh. That mixed a broad metadata scan into app startup and created avoidable allocation churn before the user asked for Storage analysis.

The correction is both a UX and performance policy:

- normal live refresh probes Storage access but never starts a broad analysis;
- returning from the one-time Full Disk Access flow still performs the promised fresh probe and starts the first explicit analysis;
- `Start Analysis`, `Rescan`, Storage Focused Check, and a newly chosen Folder Scope remain explicit scan triggers;
- path normalization is performed once per item;
- per-item temporary Foundation objects are released inside an `autoreleasepool`;
- top-three category examples use bounded insertion instead of append-and-sort for every file.

Measured after the correction:

| Scenario | Current footprint | Observed peak | Result |
| --- | ---: | ---: | --- |
| Signed debug, normal launch/refresh, 160 s | 64-90 MB | 156 MB | Pass |
| Ad-hoc-signed `-c release`, normal launch/refresh, 160 s | 60-72 MB | 156 MB | Pass |
| Explicit Folder Scope scan of the test user's home folder, about 900k files observed | 64-67 MB during sampled minute | 156 MB | Pass |

The remembered test folder was removed after the profile. The release peak fell by approximately 89% from 1,416 MB to 156 MB.

Safe improvements retained from the investigation:

- corrected `sysctl` to write into the contiguous `kinfo_proc` buffer instead of the Swift `Array` value;
- reused process-name and 4 KiB process-path buffers for a full enumeration;
- cached user-name resolution by UID within each process sample;
- capped Performance history at 60 samples and stored compact process history instead of complete UI-rich observations;
- replaced the Overview Swift Charts micro-chart with a lightweight, non-animated `Path` sparkline.

Rejected after measurement:

- per-refresh child tasks and allocator pressure-relief calls did not produce a repeatable plateau and were removed.

## Budgets and gates

Focused Diagnostics CPU gate:

- feature-exclusive symbols must remain below 0.10% average of one core in a five-minute workflow recording;
- observed: 0.0246%, gate passed.

Memory release gate:

- post-warm-up physical footprint should remain at or below 450 MB;
- transient release peak must be reduced by at least 50% from the measured 1,416 MB baseline, to at most 700 MB;
- current result: approximately 60-72 MB steady state and 156 MB peak; both gates pass.

The release run used a locally assembled, ad-hoc-signed bundle launched through Launch Services. The normal launch/refresh and a large explicit Storage scan are covered. A ten-minute Battery check and the final distribution-signed package still require physical-Mac release validation before distribution.

## Reproduction

```sh
xcrun xctrace record --template 'Time Profiler' --attach Corewise --time-limit 5m --output /tmp/Corewise-TimeProfiler.trace
footprint -p <pid> --noCategories --sample 20 --sample-duration 160
heap <pid>
```

Raw traces stay in `/tmp` and are not project artifacts.
