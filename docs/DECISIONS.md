# Decision Log

## 2026-07-08: Corewise Is Local-First

Decision: Corewise has no account, backend, analytics, or tracking in the MVP.

Reason: The product promise depends on trust and calm local diagnostics.

## 2026-07-08: No Destructive MVP Actions

Decision: Corewise may explain and point to manual review paths, but it must not delete files, empty Trash, remove startup items, kill processes, or change settings automatically.

Reason: The app should not behave like an aggressive cleaner utility.

## 2026-07-08: Synthetic Data Was Temporary And Is Now Superseded

Decision: Early synthetic values were allowed only for UI/product scaffolding and have been superseded by the no-runtime-synthetic-data rule below.

Reason: The product needed shape before real collectors existed, but the trust baseline now requires missing data to be shown as planned, unavailable, or avoided.

## 2026-07-08: Live Performance Uses Public macOS Signals

Decision: CPU, RAM, and process rankings use public macOS process and VM information where available.

Reason: Performance is the first useful real diagnostic surface and can be collected locally without private APIs.

## 2026-07-08: Performance Shows Process Rows Before Interpretation

Decision: Corewise shows individual process rows with PID, user, CPU, thread count, observed memory, RSS, and footprint when available. App grouping is a derived view, not the primary source of truth.

Reason: Monitoraggio Attività sets the user expectation; hiding process rows behind app groups makes real data look absent.

## 2026-07-08: Footprint And RSS Are Separate

Decision: Process memory footprint comes from `proc_pid_rusage(RUSAGE_INFO_V4)` when available, while resident memory remains a separate RSS-style value from `PROC_PIDTASKINFO`.

Reason: Footprint is useful context, but audit probes showed it is not always the highest or most user-comparable public memory value. RSS must stay visible instead of being hidden behind footprint.

## 2026-07-08: Primary Process Memory Uses Observed Memory

Decision: Corewise's primary process memory value is `observed memory`, the larger public value between physical footprint and resident memory. RSS remains visible as its own column.

Reason: Audit probes showed public footprint can under-report compared with resident memory for real processes. Using the larger public value keeps Corewise from hiding active processes while still avoiding private APIs, shell collection, or invented values.

## 2026-07-08: Activity Monitor Is A Plausibility Benchmark, Not A Parity Claim

Decision: Corewise should compare against Monitoraggio Attività during QA, but docs and UI must not claim exact parity with Apple's private internals.

Reason: Public APIs can expose different memory semantics than Activity Monitor's `sysmond`-backed presentation. Corewise should be honest about its sources and still be practically useful.

## 2026-07-08: No Estimated Memory Pressure

Decision: Corewise does not show a live memory-pressure estimate until a reliable public source matching macOS semantics is selected.

Reason: A weak estimate would look authoritative and repeat the trust problem the product is trying to solve.

## 2026-07-08: App Helpers Roll Up To App Names

Decision: Helper processes should be grouped under their owning `.app` bundle when a process path is readable.

Reason: Users think in apps, while macOS often exposes helpers, renderers, services, and subprocesses.

## 2026-07-08: Whole-System Wattage Is Unavailable In The MVP

Decision: Corewise should show wattage as unavailable unless a safe, public, user-approved path exists.

Reason: Unsupported sensors and elevated tools would weaken the safety model.

## 2026-07-08: Repo Docs Are The Operational Source

Decision: The repo documentation is the operational source of truth; Brain receives concise project memory.

Reason: Engineers and agents need versioned docs next to the code.

## 2026-07-08: DataMode Is Structured State

Decision: Corewise uses an explicit `DataMode` model field for `Live`, `Planned`, `Unavailable`, and `Avoided` instead of inferring provenance from source or confidence strings.

Reason: The user must be able to tell immediately whether a value is real, planned, intentionally unavailable, or intentionally avoided.

## 2026-07-08: Storage Collector Is Read-Only And Omit-Unknown

Decision: Storage reads startup volume capacity and selected known paths only. Missing, absent, or unreadable folders are omitted instead of estimated.

Reason: It is safer to show fewer real values than to fill the UI with plausible but false storage diagnostics.

## 2026-07-08: Battery Collector Reads Only Safe Basics

Decision: Battery reads charge, power source, and charging state from IOKit power-source APIs. Cycle count, maximum capacity, and condition stay unavailable until Corewise has a safe documented source.

Reason: Battery trust depends on not inventing health details or implying service status without macOS-backed evidence.

## 2026-07-08: Storage Does Not Scan Personal Folders Automatically

Decision: Storage automatic refresh reads startup volume capacity only. Downloads, Trash, user Library folders, browser caches, and developer folders remain unavailable or planned until Corewise has an explicit targeted scan flow.

Reason: macOS privacy prompts for personal folders are appropriate, but surprising prompts damage trust. Corewise should ask only when the user chooses a scoped review.

## 2026-07-08: Performance History Is Volatile And Local

Decision: Sustained CPU uses a short in-memory history window and is unavailable until enough samples exist. The history is not persisted.

Reason: Repeated load is more useful than a single spike, but local-first trust does not require storing process histories beyond the current session.

## 2026-07-08: Startup Inventory Reads Plist Metadata Only

Decision: Startup reads accessible LaunchAgents and LaunchDaemons plist metadata in read-only mode. Code signing is checked only when a readable executable path is present. Login items, background items, and privileged helpers stay unavailable or planned.

Reason: Plist metadata is useful context, but Corewise should not imply complete startup visibility or suggest raw file removal.

## 2026-07-08: No Runtime Synthetic Diagnostic Data

Decision: Corewise runtime diagnostics must not use synthetic values, synthetic apps, or invented counts. Missing features must be `Planned`, `Unavailable`, or `Avoided`.

Reason: A serious Mac diagnostic utility earns trust by showing fewer real values rather than filling pages with plausible but false data.

## 2026-07-08: User-Selected Scans Only For Personal Data

Decision: Detailed storage folders and crash reports are read only after the user chooses a folder with a picker. Automatic refresh must not scan personal folders or diagnostic report folders.

Reason: A surprising privacy prompt or silent scan would break Corewise's trust model.

## 2026-07-08: Battery Health Is Opportunistic

Decision: Cycle count, maximum capacity, and condition may be shown only when safe IOKit registry keys are present. Missing keys remain unavailable.

Reason: Battery health should not be inferred from partial data or presented as service guidance without macOS-backed context.

## 2026-07-08: Score Is Gated By Real Coverage

Decision: Corewise keeps the global score off until enough real live signals exist and the scoring model ignores planned, unavailable, and avoided values.

Reason: A premature score would look authoritative while still depending on incomplete coverage.
