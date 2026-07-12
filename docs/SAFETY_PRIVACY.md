# Safety And Privacy

## Summary

Corewise should feel useful because it explains signals clearly, not because it takes control away from the user. The MVP is local-first and non-destructive.

## Implemented

- No backend.
- No account.
- No tracking.
- No network dependency.
- Live performance sampling stays on-device.
- Current process data is used for display and grouping, not upload.
- Swap Insight reads public system swap counters, VM statistics, and process memory/page-in signals. It does not inspect swap files or claim exact per-process swap ownership.
- Memory Context is derived from public VM and swap counters and does not claim to be Activity Monitor's private memory-pressure graph.
- Storage details are read only after the user grants macOS Full Disk Access or chooses a Folder Scope fallback.
- Full Storage Analysis scans curated standard scopes only, stays metadata/size-only, and is local, optional, and revocable in System Settings.
- Storage category breakdowns are scoped to Full Storage Analysis or Folder Scope and are not cleanup recommendations or hidden System Settings Storage categories.
- Crash report metadata is read only after the user chooses a reports folder.
- Diagnostic Report Summary and Markdown copy are generated locally from the current snapshot.
- Startup plist rows can be revealed in Finder, but Corewise does not edit, disable, delete, or unload them.
- App Issues remains empty until a report folder is selected; it does not infer crash counts from other sources.
- Menu bar values reuse the current app snapshot and do not create a second background data collector.
- Settings controls local display/report preferences only. Settings controls must stay explicit preferences, not hidden permission grants or remediation shortcuts.

## Runtime Data

- Runtime diagnostics must not use synthetic values, invented apps, or invented counts.
- Missing collectors must show `Planned`, `Unavailable`, or `Avoided`.
- Sparse pages are acceptable when data cannot be read safely.

## Planned Rules

- Keep visible provenance badges for `Live`, `Planned`, `Unavailable`, and `Avoided`.
- Add source and confidence notes to every metric row.
- Keep storage scanning read-only.
- Prefer opening Finder, System Settings, or vendor-owned tools for user action.
- `Reveal in Finder` is allowed for scanned storage items because it opens location context without changing files.
- Storage drilldown is allowed only inside Full Storage Analysis results or an approved Folder Scope.
- Report export must stay local clipboard text unless a future version explicitly adds a user-chosen save action. Summary and Markdown modes must use the same snapshot and must not run extra collectors.
- Ask for permissions only when a feature clearly needs them and can explain why.
- Omit unreadable files and reports instead of estimating them.
- Document every persistent Settings preference key before implementation.
- Settings toggles can hide or show already-collected Menu Bar values and optional report summaries, but they must not enable cleanup or private data collection.
- Full Disk Access is granted only by the user in macOS System Settings; Corewise opens the pane, waits for the app to become active again, then checks automatically. It cannot grant access programmatically.
- Before Full Disk Access, Corewise probes only dedicated protected sentinels. It must not touch each intended scan folder to infer permission because those reads can trigger separate Files & Folders prompts.
- Folder Scope fallback uses one security-scoped bookmark after explicit user choice, reuses it without another picker, and can be forgotten.

## Avoided

- Sudo-based collection.
- Private APIs for consumer-facing claims.
- Automatic file deletion.
- Silent background scanning without Full Disk Access or explicit Folder Scope.
- Whole-disk raw scans of `/`, `/System`, `/private`, Trash, or all files in v1.
- Persistent access to selected storage folders without explicit consent and a visible forget path.
- Silent background scanning of diagnostic report folders.
- Reading document contents for diagnostics.
- Uploading process, file, crash, or device data.
- Including raw crash stack traces or document contents in exported summaries.
- Claiming certainty when macOS only exposes a partial signal.
- Presenting likely swap contributors as exact swap owners.

## Action Policy

Allowed actions:

- Explain what a metric means.
- Open a relevant folder or settings pane when the user chooses.
- Reveal a scanned item in Finder when the user chooses.
- Copy a local Markdown diagnostic summary.
- Suggest a manual review path.
- Show that a signal is unavailable.

Not allowed in the MVP:

- Deleting files.
- Emptying Trash.
- Removing launch agents or daemons.
- Killing processes automatically.
- Changing system settings automatically.
- Settings toggles that enable automatic cleanup, broad personal-folder scans, process killing, telemetry, tracking, or private API reads.
- Presenting private-sensor readings as product truth.
