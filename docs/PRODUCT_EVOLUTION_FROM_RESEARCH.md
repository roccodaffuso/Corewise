# Corewise Product Evolution From Research

Last updated: 2026-07-10

## Summary

Corewise should evolve into a credible local Mac diagnostic utility, not a cleaner, not a full Activity Monitor clone, and not a broad dashboard. The strongest product direction is:

1. Performance explained better than Activity Monitor.
2. Manual storage discovery that respects privacy.
3. A local diagnostic report that helps the user understand or share what is happening.

The app should keep showing fewer numbers if that is what it takes to keep every number real. The next evolution should make the existing real data easier to trust, compare, explain, and act on safely.

## Voice-of-Customer Validation - 2026-07-10

### Core job to be done

The strongest cross-source job is not continuous system monitoring. It is event-driven diagnosis:

> When my Mac suddenly feels slow, hot, battery-hungry, or full, help me understand what changed, whether it matters, and the safest useful next step without making me interpret Activity Monitor or trust an automatic cleaner.

This is a high-confidence qualitative finding. It recurs across recent r/MacOS, r/mac, r/macapps, Apple Support Community, and Mac App Store evidence. The sample is online and therefore skews more technical and more frustrated than the full Mac population.

### Ranked user needs

| Rank | User need | Confidence | Evidence pattern | Product consequence |
| --- | --- | --- | --- | --- |
| 1 | Explain the symptom, not just the metric | High | Users repeatedly ask whether memory pressure, swap, heat, or battery drain is normal even after opening Activity Monitor. | Lead with a plain-language conclusion, the evidence behind it, and what to do next. |
| 2 | Reveal what is actually consuming storage | High | “System Data” threads recur after users have tried tutorials, Finder, Terminal, cleaners, and deleting obvious files. | Storage must identify the responsible folder, app, snapshot, cache, or volume relationship where the approved scan can prove it. |
| 3 | Keep cleanup safe and user-controlled | High | Community advice repeatedly warns against blind deletion; trust rises when a tool explains what it found and lets the user decide. | Preserve read-only analysis, Finder reveal, clear scope, and explicit warnings. Do not add one-click cleanup. |
| 4 | Translate processes into apps and understandable causes | Medium-high | Users want app-level grouping, hidden child processes, timelines, and an explanation of unfamiliar background services. | Group helpers under the owning app when reliable, explain common system processes, and keep raw processes available as evidence. |
| 5 | Show whether the problem is persistent or transient | Medium-high | Single Activity Monitor snapshots often look normal while users report intermittent drain, heat, beachballs, or post-update regressions. | Short history should answer “what changed” and “is it still happening,” not exist as decoration. |
| 6 | Produce evidence another person can use | Medium | Apple Support workflows repeatedly ask users to paste an EtreCheck-style report and then rely on a helper to interpret it. | Keep a concise local report that is readable by the owner and shareable with a trusted helper. |

### Segment hierarchy

Corewise should not average all users into one dashboard persona.

1. **Primary - Triggered troubleshooter.** Opens the app because the Mac feels wrong or a task has stopped. Needs a fast answer, reassurance when appropriate, and one safe action.
2. **Secondary - Power user or developer.** Wants process grouping, deeper metrics, sorting, history, paths, and evidence without losing native density.
3. **Tertiary - Trusted helper.** Needs a compact, privacy-conscious report that makes remote diagnosis possible.

The primary segment should determine Overview and the first-run experience. Performance depth should serve the secondary segment progressively. Report export should serve the tertiary segment without turning Corewise into a support bundle collector.

### Product priority correction

The current architecture is directionally aligned: no health score, read-only storage, distinct CPU and Memory modes, cautious language, local reports, and no automatic cleanup. The highest-value remaining gaps are workflow gaps rather than more diagnostic categories:

1. A symptom-led entry point: `Slow`, `Hot`, `Battery draining`, `Storage full`, or `Just checking`.
2. A temporal explanation: what changed recently, whether the signal persists, and which app or system service coincided with it.
3. Stronger app/process grouping with plain-language background-service explanations.
4. Storage attribution that turns the catch-all “System Data” problem into inspectable, approved-scope causes.
5. A short incident summary that can be copied without exposing file contents or stack traces.

Do not prioritize another generic dashboard, more gauges, automatic remediation, a health score, decorative charts, or full Activity Monitor parity. Those expand surface area without solving the dominant user job.

### Evidence links

- [Users ask whether memory pressure matters when the Mac still feels fine](https://www.reddit.com/r/MacOS/comments/1r0eg89/is_memory_pressure_even_real_or_is_my_mac_just/)
- [Users remain confused by swap after closing apps](https://www.reddit.com/r/mac/comments/1sja43o/swap_question/)
- [System Data can block updates and active work](https://www.reddit.com/r/MacOS/comments/1rj6xp9/system_data_is_expanded_to_over_half_of_storage/)
- [A storage visualizer exposed an otherwise hidden 83 GB cause](https://www.reddit.com/r/MacOS/comments/1s2ov20/macos_storage_issues_system_data/)
- [Battery drain can remain unexplained even when Activity Monitor looks normal](https://www.reddit.com/r/MacOS/comments/1rpqglb/battery_life_using_macos_2631/)
- [Users ask for basic monitoring with clearer output and visuals](https://www.reddit.com/r/macbookpro/comments/1u50j2r/activity_monitor_alternatives/)
- [Power users ask for richer process context, grouping, and timelines](https://www.reddit.com/r/macapps/comments/1udaids/processspy_advanced_process_monitor_for_mac/)
- [DaisyDisk reviews emphasize finding unexplained storage and deciding what to remove](https://apps.apple.com/us/app/daisydisk/id411643860?mt=12&platform=mac&see-all=reviews)
- [Apple Support workflows use shareable reports to diagnose a slow Mac](https://discussions.apple.com/thread/256262749)

### Research gap before major new feature work

Online evidence is sufficient to set the product thesis, but not to finalize messaging or onboarding. Before adding a new diagnostic surface, run 8-12 short workflow interviews or usability sessions, with at least five data points for the primary segment and five for the power-user/helper segments combined. Test real trigger moments, not feature preference lists.

Ask participants to recreate the last time their Mac felt wrong, show what they tried, explain what they feared deleting or quitting, and identify the exact point at which they would trust Corewise's conclusion.

## Research Inputs

This document is based on:

- Corewise repo state and current implemented diagnostics as of 2026-07-09.
- `last30days v3.7.0` research run on 2026-07-09 for Mac diagnostic utilities, system monitors, storage discovery, menu bar monitors, and report workflows.
- Recent user feedback from Corewise app QA sessions, especially around Activity Monitor alignment, storage usefulness, menu bar density, and premium visual quality.
- Apple-facing reference behavior:
  - [Activity Monitor User Guide](https://support.apple.com/guide/activity-monitor/welcome/mac)
  - [View memory usage in Activity Monitor](https://support.apple.com/en-gb/guide/activity-monitor/actmntr1004/mac)
  - [Optimize storage space on your Mac](https://support.apple.com/guide/mac-help/optimize-storage-space-sysp4ee93ca4/mac)
- Community signals:
  - [Most Beautiful Mac Apps](https://www.reddit.com/r/macapps/comments/1urkssy/most_beautiful_mac_apps/)
  - [Free Mac diagnostic app discussion](https://www.reddit.com/r/macapps/comments/1ul243j/we_built_a_free_mac_diagnostic_app_because_we/)

## Product Thesis

Corewise wins when it answers:

- What is slowing my Mac right now?
- Is this memory or swap situation normal?
- What is taking space, after I choose what Corewise may scan?
- What can I safely review manually?
- What can I copy into a local report without exposing private contents?

Corewise loses trust when it:

- Looks like a generic dashboard.
- Shows values that do not resemble what users see in Activity Monitor.
- Uses a score before the scoring model is real.
- Makes storage claims without a user-selected scan.
- Repeats provenance badges so much that the UI feels noisy.
- Uses cleaner-like remediation wording.

## What We Are Doing Correctly

### Zero Mock Runtime

The decision to remove runtime mock data is correct. Users compare Corewise to Activity Monitor and Finder. A fake number damages trust faster than an unavailable value.

Keep:

- `Live`, `Planned`, `Unavailable`, and `Avoided`.
- No synthetic apps, folders, crashes, or scores.
- No fake health score.

### Performance First

Performance should remain the flagship page. It is the area where users most quickly decide whether Corewise is credible.

Keep:

- Individual process rows.
- CPU and memory sorting.
- Observed memory with RSS visible.
- Top process rows in Overview and menu bar.
- Corewise included as a real process, with `This app` context.
- App grouping as secondary explanation, not replacement for process rows.

### Full Storage Analysis

Updated 2026-07-09: the folder-by-folder model was too weak for user value. Corewise should use explicit macOS Full Disk Access as the primary consent path for broad local storage analysis, while keeping Folder Scope as fallback.

Keep:

- Startup volume capacity read automatically.
- Full Storage Analysis only after the user grants Full Disk Access in macOS.
- Curated standard scopes only, not raw whole-disk scans.
- Folder Scope fallback only after picker selection.
- No automatic cleanup.
- Reveal/Open in Finder as the safe action.
- Clear `Full Disk Access` or `Folder Scope` source labels.

### Swap Insight Framing

The current product framing is correct: Corewise can explain system swap pressure and likely contributors, but it must not claim exact per-process swap ownership.

Keep:

- Swap used, total, available, encryption state, trend, and rates.
- Likely contributors based on memory, page-ins, and growth.
- Clear copy that macOS public APIs do not expose exact per-process swap ownership.

### Premium Visual Direction

The visual redesign is not cosmetic. Recent community comments around beautiful Mac apps reinforce that users expect Mac utilities to follow Apple-native conventions. If Corewise looks cheap, its data feels cheap.

Keep:

- Soft macOS material.
- Restrained sidebar selection.
- Stable page rails.
- Monospaced numeric values.
- Muted natural semantic colors.
- Dense tables where data needs comparison.

## What Must Evolve Next

## 1. Performance Explanations V3

### Problem

Activity Monitor shows data, but it does not explain why common processes appear. Corewise can differentiate itself by explaining process patterns without pretending causality.

### Add

- A `What this process usually means` layer derived from live process rows.
- Explanations for:
  - browser helpers and renderers;
  - Electron-style apps such as Codex-like helpers;
  - `WindowServer`;
  - `mdworker` and Spotlight;
  - `fileproviderd`, `bird`, and iCloud sync;
  - media/video decode services;
  - Corewise itself.
- A compact explanation drawer or inline secondary line for selected rows.
- A `Normal / Worth watching / Investigate` language model based only on live thresholds and repeated history.

### Do Not Add

- Kill process buttons.
- Claims that a process is bad.
- Vendor blame without evidence.
- Hidden process filtering that makes numbers diverge from Activity Monitor.

### Design Direction

Performance should feel like a professional instrument panel:

- Summary strip at top: CPU, memory, swap, process count, thread count.
- Segmented control: `CPU / Memory`.
- Top pressure panel with top 3-5 rows.
- Dense process table as the source of truth.
- Source note at table level, not `Live` badge on every row.

### Success Criteria

- A user can identify the top CPU and memory process in less than 5 seconds.
- A user can understand why `fileproviderd`, `WindowServer`, or browser helpers appear without leaving the app.
- The table remains visually comparable to Activity Monitor without claiming exact parity.

## 2. Memory Pressure Explanation

### Problem

Users understand memory through Activity Monitor's Memory tab: memory used, cached files, swap used, compressed, wired, and pressure. Corewise has real VM fields and Swap Insight, but it still needs a clear explanation layer.

### Add

- A `Memory Pressure Context` panel in `Performance > Memory`.
- Fields:
  - physical memory;
  - used memory;
  - wired memory;
  - compressed memory;
  - cached/file-backed memory if derived clearly;
  - swap used;
  - swap trend;
  - swap in/out rate.
- Plain-language states:
  - `Quiet`;
  - `Using compression`;
  - `Using swap`;
  - `Swap growing`;
  - `Review top memory processes`.

### Rules

- Do not call it Activity Monitor memory pressure unless Corewise has a reliable public source for the same signal.
- Do not show a green/yellow/red pressure chart unless the semantics are documented.
- If pressure is inferred, label it as context, not as the system pressure value.

### Design Direction

Use a calm panel with one main statement:

> Memory is using swap, but swap is stable.

Then show the numbers beneath it. The insight should be readable before the table.

### Success Criteria

- The user understands whether swap is stable or growing.
- The user sees which processes are likely contributing.
- No row says a process owns a specific amount of swap.

## 3. Storage Explorer V3

### Problem

Startup volume capacity is useful but not enough. Users need to understand what takes space. The best current product path is explicit Full Disk Access for curated local storage scopes, with Folder Scope as a narrower fallback. Corewise still must not scan raw `/`, `/System`, `/private`, Trash, or the whole disk.

### Add

- A stronger `Storage Analysis` surface.
- File type/category breakdown inside approved scopes:
  - apps;
  - archives;
  - video;
  - audio;
  - images;
  - documents;
  - developer/build data;
  - other.
- Largest folders and largest files with sorting.
- Breadcrumb navigation for Folder Scope drilldown.
- Scan parent / scan selected folder inside approved scope.
- Reveal in Finder for rows.
- Scan summary:
- source: Full Disk Access or Folder Scope;
  - current folder;
  - scanned size;
  - file count;
  - folder count;
  - unreadable count;
  - duration;
  - last updated.

### Do Not Add

- Delete buttons.
- Empty Trash.
- Move to trash.
- Raw whole-disk scans of `/`, `/System`, `/private`, Trash, or all files.
- Cleanup, delete, move, or empty-trash actions.
- Persistent access beyond Full Disk Access or a visible revocable Folder Scope.

### Design Direction

Storage should be less empty before scan and more exploratory after scan:

- Hero: available space, total volume, volume name.
- Volume panel: Used red, Available green, with clear labels.
- Manual scan toolbar: compact, calm, user-initiated.
- Explorer results: table/list first, chart second.
- Empty state: premium and clear, not a warning card.

### Success Criteria

- Before scan, the page clearly explains what Corewise knows and what it does not scan.
- After scan, the user can identify the largest folder or file without reading dense prose.
- No storage detail appears unless it comes from the selected folder or startup volume.

## 4. Diagnostic Report V3

### Problem

Users often need a readable summary of what is happening, either for themselves or to share with a trusted helper. This is where Corewise can become EtreCheck-like without collecting sensitive data or uploading anything.

### Add

- A stronger report structure:
  - Summary;
  - Notable Findings;
  - Performance;
  - Memory And Swap;
  - Storage;
  - Battery;
  - Thermal;
  - Startup;
  - App Issues;
  - Limits And Missing Data;
  - Manual Next Steps.
- A `Copy Summary` action for a short version.
- A `Copy Markdown` action for a fuller version.
- Section-level source/confidence notes.
- Optional inclusion of selected folder scan and selected crash report summary, controlled by Settings.

### Do Not Add

- File upload.
- Automatic file save.
- Stack traces.
- Raw crash body.
- Document contents.
- Full personal folder listings unless already visible in the selected scan UI.

### Design Direction

Report should feel like a document preview, not another dashboard:

- More text hierarchy.
- Fewer tiles.
- Good spacing.
- Clear copy buttons.
- Strong distinction between available data and unavailable data.

### Success Criteria

- The report is useful even when no storage or crash folder has been selected.
- The report becomes much more useful after a selected scan.
- A copied report does not include raw sensitive contents.

## 5. Overview As The Triage Surface

### Problem

Overview should not be a mini version of every page. It should tell the user where to look first.

### Add

- A `Right now` strip:
  - CPU total;
  - memory used;
  - swap used/trend;
  - top CPU process;
  - top memory process;
  - storage free;
  - battery;
  - thermal state.
- A `Needs review` area generated only from real findings:
  - swap growing;
  - sustained CPU;
  - low storage;
  - repeated crash reports after selection;
  - startup item recently added;
  - battery unavailable or service state only if macOS provides it.
- A quiet `Global Score: Planned` row, secondary.

### Remove Or De-Emphasize

- Any hero copy that sounds like the app is incomplete.
- Any coverage metric that looks like a health score.
- Data Access as first-viewport content.

### Design Direction

The first viewport should say:

> Corewise is reading real local signals. Here is what matters now.

Not:

> Here is everything Corewise cannot do yet.

### Success Criteria

- The first viewport communicates usefulness before limitations.
- Limitations remain accessible and honest below the first viewport.
- No score dominates the page.

## 6. Menu Bar Monitor

### Problem

The menu bar is valuable because it is glanceable. It should not become a mini app.

### Add

- Top three CPU rows.
- Top three memory rows.
- Compact bars for CPU, memory, and swap.
- Optional row visibility from Settings.
- A click path to open Corewise directly into Performance.

### Do Not Add

- Refresh button.
- Many controls.
- Full tables.
- Alerts before there is a notification strategy.

### Design Direction

Make it feel like a small premium instrument:

- Three metric tiles.
- Two ranked lists.
- One primary action.
- Soft material and restrained color.

### Success Criteria

- The user can understand current CPU, memory, swap, and top processes in one glance.
- The popover remains readable around 320-380 px.
- It shares the same visual language as the main app.

## 7. Battery, Thermal, Startup, App Issues

These sections should stay useful but not pretend to be complete.

### Battery

Keep:

- Charge.
- Power source.
- Charging state.
- Cycle count, maximum capacity, and condition only when safe IOKit keys are present and plausible.

Add:

- Stronger source/confidence wording.
- A guard against implausible health values.
- A clear explanation when macOS does not expose a value.

Avoid:

- Battery risk score.
- Service claims unless macOS provides the state.

### Thermal

Keep:

- `ProcessInfo.thermalState`.

Add:

- If CPU history shows repeated high load, show likely contributors as correlation only.

Avoid:

- Temperatures.
- SMC.
- Private sensors.
- Watt claims.

### Startup

Keep:

- Read-only LaunchAgents/LaunchDaemons inventory.

Add:

- Better grouping by user/system.
- Better explanation of RunAtLoad and KeepAlive.
- Stronger signing state where readable.
- Manual guidance to System Settings or vendor docs.

Avoid:

- Disable/remove actions.
- Claims about modern login items until a safe source exists.

### App Issues

Keep:

- User-selected DiagnosticReports only.

Add:

- Better empty state.
- Stronger repeated crash patterns after scan.
- Copy explaining that reports can contain sensitive metadata.

Avoid:

- Stack traces in UI.
- Automatic report folder access.

## Design Evolution

## Design Goal

Corewise should feel like an Apple-native pro utility: calm, soft, precise, and trustworthy.

The design should not feel like:

- a SaaS analytics dashboard;
- a cleaner app;
- a gaming system monitor;
- a dark card grid;
- a clone of Activity Monitor.

## Visual Principles

### 1. Real Mac Materials

Use macOS material and transparency as structure, not decoration. Background transparency should make the app feel integrated with the system, but data panels must remain legible.

### 2. Stable Page Rails

Every page should use the same top padding, hero height, first summary grid, panel spacing, and content width. Switching pages should not create the visual "step" effect.

### 3. Numbers Need Discipline

Diagnostic numbers should use:

- monospaced digits;
- right alignment in tables;
- stable units;
- no hidden scale ambiguity;
- no unlabeled chart axes.

### 4. Color Is Semantic

Use:

- moss green for live/good/available;
- muted red for used storage or critical;
- amber for attention/swap pressure;
- blue/teal for planned/info;
- graphite/stone for neutral surfaces.

Do not invent colors per chart.

### 5. Tables For Comparison, Cards For Summary

Use cards for summaries. Use tables for process rows, startup rows, crash rows, and storage results. Users compare rows faster in tables.

### 6. Provenance Without Noise

Show provenance at the right level:

- metric cards can show data mode;
- dense tables should have one source note;
- report sections should have source/confidence notes;
- avoid `Live` badges on every repeated row.

## Remove Or De-Emphasize

- Health score as primary concept.
- Coverage as a hero concept if it reads like health.
- Data Access as first-viewport education.
- Repeated badges in dense lists.
- Large empty panels.
- Cleaner-like wording.
- Any button that implies automatic fixing.

## Prioritized Next Backlog

### P0: Performance Explanation V3

Why: biggest trust driver and most frequent user comparison point.

Deliverables:

- process insight taxonomy;
- selected-row explanation;
- clearer top pressure panel;
- table-first UI cleanup.

### P0: Storage Explorer V3

Why: storage page currently has safe data, but not enough discovery value before or after scan.

Deliverables:

- file type breakdown inside selected folder;
- better largest folders/files;
- Explorer UI polish;
- safer Finder actions.

### P1: Memory Pressure Context

Why: users already understand memory through Activity Monitor, swap, and pressure. Corewise must translate those signals.

Deliverables:

- memory context panel;
- swap trend statement;
- contributor explanation;
- no false Activity Monitor parity claim.

### P1: Report V3

Why: report is the shareable artifact that makes Corewise useful beyond live monitoring.

Deliverables:

- clearer sections;
- stronger notable findings;
- local copy flows;
- source/confidence in every section.

### P2: Overview Triage

Why: Overview should guide the user, not summarize the whole app.

Deliverables:

- Right Now strip;
- Needs Review from real findings;
- Data Access moved lower;
- score stays planned.

### P2: Startup/App Issues Polish

Why: useful, but secondary until Performance, Storage, and Report feel complete.

Deliverables:

- better startup grouping;
- better empty state for reports;
- repeated crash patterns after scan.

## Acceptance Criteria For The Next Product Milestone

Corewise can be considered meaningfully evolved when:

- A user can open Overview and immediately see useful real signals.
- A user can open Performance and understand the top CPU/memory/swap contributors.
- A user can choose a folder and see a useful storage explorer without automatic scanning.
- A user can copy a local report that is readable, safe, and source-aware.
- Every visible number has a source or a clear unavailable state.
- The visual system feels consistent when switching between pages.
- The app never implies automated remediation, private hardware readings, or exact Activity Monitor parity.

## Documentation Follow-Up

When these changes are implemented, update:

- `docs/PROJECT_STATUS.md`
- `docs/ROADMAP.md`
- `docs/DATA_SOURCES.md`
- `docs/DESIGN_SYSTEM.md`
- `docs/ARCHITECTURE.md`
- `docs/SAFETY_PRIVACY.md`
- `docs/DECISIONS.md`

Each update should preserve the central product truth:

> Corewise is a local-first diagnostic utility that explains real Mac signals clearly and leaves every change under user control.
