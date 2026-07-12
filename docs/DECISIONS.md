# Decision Log

## 2026-07-09: Signal System replaces health scoring

Decision: `HealthSnapshot` no longer contains a numeric health score or overall verdict. A pure resolver ranks only supported live metrics with typed roles and uses conservative attention language.

Reason: coverage, planned data, and static findings cannot safely support a diagnosis. `No urgent live signals detected` is accurate without claiming the Mac is healthy.

## 2026-07-09: Content is tonal; material belongs to chrome

Decision: Corewise uses dynamic solid content surfaces, native tables, dividers, and inspectors. Material is reserved for navigation and transient UI.

Reason: repeated glass cards flattened hierarchy and made coverage look like health.

## 2026-07-09: Storage progress reports only observed work

Decision: scans publish scope position, file/folder/unreadable counts, and elapsed time. Corewise does not show a percentage when the total is unknowable, and cancelled partial results are not published.

Reason: a fabricated percentage would weaken the product's trust model.

## 2026-07-09: Menu bar and Quick Actions share typed routing

Decision: the main window, menu bar, and `⌘K` palette route through `AppRouteStore` and typed descriptors without notifications or a second collector.

Reason: shared navigation and snapshot state keep the app coherent, testable, and efficient.

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

## 2026-07-08: Process Enumeration Uses BSD Process List First

Decision: Corewise enumerates process IDs with `sysctl KERN_PROC_ALL` first and keeps `proc_listallpids` as a fallback.

Reason: Audit probes showed `proc_listallpids` could omit high-memory Codex renderer processes even though direct public PID reads succeeded. The BSD process list better matches `ps` and Monitoraggio Attività visibility while staying inside public local APIs.

## 2026-07-08: Process CPU Converts Mach Timebase

Decision: Corewise converts process task CPU ticks with `mach_timebase_info` before calculating the 1 second CPU percentage.

Reason: Audit probes showed `pti_total_user` and `pti_total_system` were Mach timebase ticks on the current Mac, not already-normalized nanoseconds. Treating them as nanoseconds made Corewise under-report readable process CPU by roughly the timebase factor.

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

Decision: Storage automatic refresh reads startup volume capacity only before storage access exists. Downloads, user Library folders, browser caches, and developer folders require explicit Full Disk Access or Folder Scope. Trash remains avoided in v1.

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

## 2026-07-08: Overview Leads With Live Signals, Not Score

Decision: The Overview hero uses `Live Signals` plus data coverage instead of a placeholder health score.

Reason: A first-viewport score placeholder makes the product look unfinished or unreliable. Live signal coverage is verifiable and preserves trust while global scoring remains planned.

## 2026-07-08: Coverage Counts Signal Families

Decision: Overview coverage counts diagnostic signal families, not every process, chart point, launch plist, or crash row.

Reason: Row-level coverage can produce confusing scales such as hundreds of live values. A small family-level count is easier to trust and does not imply device health.

## 2026-07-08: Corewise Follows Diagnostic Workflows

Decision: Corewise should prioritize Performance, Full Storage Analysis, and local Diagnostic Report workflows over filling every section with equal visual weight.

Reason: last30days research and product review showed that trust comes from answering concrete questions with real local data, not from looking like a complete but shallow dashboard.

## 2026-07-08: Dense Tables Use Table-Level Provenance

Decision: Dense process tables should use a source note for live provenance instead of repeating `Live` badges on every row.

Reason: Repeated badges make operational data harder to scan. Provenance remains visible without overwhelming the primary numbers.

## 2026-07-08: Report Export Is Local Clipboard Markdown

Decision: Diagnostic Report exports a local Markdown summary to the clipboard only. It must not upload, persist, include stack traces, include raw crash report bodies, or include document contents.

Reason: The report should be useful like a diagnostic summary while staying inside Corewise's local-first and non-destructive trust model.

## 2026-07-08: Report Has Summary And Markdown Modes

Decision: Diagnostic Report should expose both a short Summary and a fuller Markdown export, generated from the same current `HealthSnapshot`.

Reason: Users need a fast readable diagnostic view and a more complete EtreCheck-like text artifact, but both must stay traceable to already-visible local data.

## 2026-07-08: Startup And App Issues Are Review Workflows

Decision: Startup should present launch plist rows as a compact read-only inventory, and App Issues should stay empty until the user selects diagnostic reports.

Reason: These areas can look scary if over-interpreted. Corewise should help the user review provenance and patterns without implying that plist files or one-off crashes are automatically problems.

## 2026-07-08: Menu Bar Reuses The Main Snapshot

Decision: The menu bar monitor should reuse `HealthDashboardStore` and show only compact values already available in the main app.

Reason: A menu bar surface is useful for quick trust and visibility, but a second collector would add complexity and could make values diverge from the main diagnostic pages.

## 2026-07-08: Process Insights Are Explanatory, Not Causal

Decision: Corewise may explain common live process patterns such as helpers, renderers, WindowServer, Spotlight indexing, file provider sync, and Corewise itself, but it must not present those explanations as proof of root cause.

Reason: Process names are useful context, but a serious diagnostic app should avoid false certainty or automatic remediation advice.

## 2026-07-08: Storage Drilldown Is Session-Only

Decision: Corewise may let the user drill into folders discovered by a manual storage scan, but the selected root/current folder stay in memory only and no security-scoped bookmark is persisted in this version.

Reason: Drilldown makes storage useful without reintroducing surprising personal-folder scanning or durable permission ambiguity.

## 2026-07-09: Settings Is A Native macOS Scene, Not A Diagnostic Section

Decision: Corewise Settings should mature inside the existing SwiftUI `Settings` scene and should not be added to the main diagnostic sidebar.

Reason: The sidebar is for diagnostic workflows. Settings is configuration, privacy explanation, and display behavior; making it another dashboard page would dilute the product structure and feel less macOS-native.

## 2026-07-09: Settings V1 Controls Display And Report Preferences Only

Decision: Settings V1 may persist Performance default focus, Report defaults, optional report summary inclusion, and visible Menu Bar rows. It must not change data collection scope.

Reason: These controls are useful and low-risk. Launch at login, refresh interval, remembered folders, and broad scan controls need separate safety decisions before implementation.

## 2026-07-09: Swap Insight, Not Swap Ownership

Decision: Corewise shows system swap context, swap trend, swap in/out rates, swapped VM pages, encryption state, and likely memory-pressure contributors. It must not say that a process owns a specific amount of swap.

Reason: Public macOS APIs expose useful system swap and process memory/page-in signals, but they do not provide reliable exact per-process swap ownership. Showing contributors as inference preserves usefulness without inventing certainty.

## 2026-07-09: System Materials Before Custom Glass

Decision: Corewise uses native macOS material as the base and applies custom translucent surfaces only through shared UI roles such as hero, panel, tile, table row, source note, and menu bar tile.

Reason: Premium transparency should clarify hierarchy and trust. Applying decorative glass everywhere would reduce legibility and make Corewise feel less native.

## 2026-07-09: Performance Is The Flagship Diagnostic Page

Decision: Performance gets the strongest operational hierarchy: summary strip, CPU/Memory focus control, pressure panel, dense process table, table-level source note, and Swap Insight in Memory mode.

Reason: The user’s trust concern centered on real CPU/RAM numbers. A serious Corewise redesign must make live process data easier to scan than the surrounding explanatory panels.

## 2026-07-09: Data Access Supports Trust But Does Not Lead The First Viewport

Decision: Data Access remains visible but secondary to live signals and operational data.

Reason: Provenance matters, but leading with missing/planned access made Corewise feel incomplete. The first viewport should show what Corewise can currently read.

## 2026-07-09: Storage Gets More Volume Context Before More Permissions

Decision: Corewise should enrich automatic Storage with safe startup-volume metadata before adding broader folder access: important/free capacity, Finder-style free capacity, opportunistic capacity when present, volume name, format, local/internal flags, and read-only state.

Reason: The Storage page needs to feel useful before a manual scan, but broad automatic folder enumeration would violate the product's privacy posture. Volume metadata gives more real information without opening personal folders.

## 2026-07-09: Corewise Explains Activity Monitor-Like Signals

Decision: Corewise should explain live CPU, memory, swap, and process rows with plain-language context while keeping Activity Monitor as a plausibility benchmark, not a parity promise.

Reason: Users compare Corewise to Activity Monitor first. The product earns trust by showing comparable public signals and explaining common process patterns, not by claiming private sysmond-level equivalence.

## 2026-07-09: Memory Context Is Not Activity Monitor Pressure

Decision: Corewise may derive `Memory Context` from public VM and swap counters, but it must not call that value Activity Monitor memory pressure.

Reason: Apple exposes useful public VM components, but not the exact private memory-pressure graph semantics. A clear Corewise context panel is useful without pretending to be the same signal.

## 2026-07-09: Storage Categories Require Explicit Access

Decision: Storage category breakdowns may be shown only after explicit access: Full Disk Access granted in macOS, or a user-selected Folder Scope fallback.

Reason: Category discovery is useful, but hidden personal-folder classification would reintroduce privacy surprises and cleaner-like behavior. Full Disk Access makes the broad consent explicit and revocable; Folder Scope keeps a narrower option.

## 2026-07-09: Corewise Classifies Approved Scopes, Not Hidden Global Storage Categories

Decision: Corewise uses its own transparent approved-scope taxonomy for Applications, Development, Documents, Photos, Video, Music, Archives & Installers, Cache & Temporary, System-like, Other, and Unreadable. It must not claim to reproduce macOS System Settings Storage categories.

Reason: macOS does not expose that global category breakdown as a stable public API. A classifier based on approved paths, bundle/package hints, `UTType`, and extension fallback is useful and explainable without inventing whole-device numbers.

## 2026-07-09: Full Storage Analysis Uses Full Disk Access, Not Folder-By-Folder UX

Decision: Corewise's primary Storage flow is `Enable Full Storage Analysis`: guide the user to grant Full Disk Access in macOS, detect likely access, then scan curated standard scopes once on return from that permission flow. Later broad scans require an explicit action or Storage Focused Check. Folder Scope remains a secondary fallback and can be forgotten.

Reason: Users expect Storage to become useful without manually classifying folder by folder. Full Disk Access is the clean macOS-level consent for broad local storage analysis; Corewise still stays read-only, local, revocable, and avoids `/`, `/System`, `/private`, Trash, and raw whole-disk scans in v1.

## 2026-07-09: Native Structure Needs A Distinct Corewise Instrument Layer

Decision: Keep native macOS navigation, tables, inspectors, controls, and accessibility behavior, but give Corewise a restrained proprietary layer: adaptive graphite tones, a signal glyph, a low-contrast instrument grid, stronger numeric hierarchy, and tonal instrument surfaces limited to focal diagnostics.

Reason: The first Signal System implementation removed the old card-heavy problems but over-corrected into stock SwiftUI. Premium clarity and product identity are compatible when distinction is concentrated in hierarchy and a few repeated signature elements rather than decorative effects or glass everywhere.

## 2026-07-10: Storage Consent Is One Full Disk Access Flow

Decision: Full Disk Access is the sole primary Storage consent path. Corewise opens macOS System Settings once, waits for app activation, forces a fresh dedicated FDA probe, and begins the curated read-only analysis automatically. It must not probe Documents, Downloads, Desktop, or every intended scan scope before consent. Folder Scope remains a secondary one-time bookmark fallback.

Reason: Probing each standard folder can trigger separate Files & Folders consent prompts and creates a tedious folder-by-folder experience. Apple requires the person to grant Full Disk Access in System Settings; Corewise can simplify everything around that system-owned step but cannot bypass it.

## 2026-07-10: Local Bundle Signing Must Preserve TCC Identity

Decision: The local run script assembles resources in the standard macOS bundle layout and signs the completed app with an available Apple Development identity, using `COREWISE_CODESIGN_IDENTITY` as an override and ad-hoc signing only as fallback.

Reason: An ad-hoc executable identifier and unsealed bundle do not provide a stable identity for macOS privacy permissions. A stable bundle identifier and signed designated requirement let TCC recognize Corewise across normal local rebuilds.

## 2026-07-10: CPU And Memory Are Distinct Performance Workflows

Decision: CPU and Memory reuse one live process sample but must derive different eligible rows, columns, sort choices, summary context, and inspector priority. CPU focuses on interval activity, accumulated CPU time, and threads. Memory focuses on observed memory, footprint, RSS, page-ins, compression, and swap context.

Reason: Reordering the same table does not help the user answer two different questions. CPU should explain what is working now; Memory should explain what is holding physical memory and whether broader VM/swap signals deserve review.

## 2026-07-10: Focused Check Reuses One Volatile Snapshot Stream

Decision: Focused Check starts from a user-reported symptom and reuses the existing store-owned snapshot refresh. Slow, Hot, and Battery aggregate bounded volatile evidence; Storage completes only from a real approved-scope scan; Just Checking resolves the current attention summary immediately.

Reason: Users need persistence and interpretation, not another sampler. One stream keeps values coherent, limits overhead, and lets a check survive navigation or main-window closure without adding telemetry or persistence.

## 2026-07-10: Evidence Is Explanatory And Deep-Linkable, Never Causal

Decision: A Focused result contains at most three typed evidence items, one action, and separate limitations. App groups use normalized bundle path plus user where available, raw processes remain authoritative, and Storage separates classified scope from outside-scope space.

Reason: The workflow should answer what was observed and what to inspect next without blaming an app, inventing removable space, or disguising coverage as a conclusion.

## 2026-07-10: Normal Refresh Never Starts A Broad Storage Scan

Decision: The two-second live refresh may read startup-volume capacity and probe whether Storage access exists, but it must not enumerate Full Storage Analysis or remembered Folder Scope contents. Broad enumeration starts only after the user completes the one-time permission flow, explicitly starts/rescans an analysis, chooses a Folder Scope, or starts a Storage Focused Check.

Reason: Malloc high-water evidence showed an implicit launch-time Full Storage Analysis caused the measured 1,416 MB transient footprint peak. Separating the fast signal refresh from explicit metadata enumeration reduced the release peak to 156 MB and prevents an expensive, surprising scan from starting merely because the app opened.
