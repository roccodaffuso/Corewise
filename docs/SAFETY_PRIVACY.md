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
- Storage details are read only after the user chooses a folder.
- Crash report metadata is read only after the user chooses a reports folder.
- Diagnostic Report copy is generated locally from the current snapshot.

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
- Report export must stay local clipboard text unless a future version explicitly adds a user-chosen save action.
- Ask for permissions only when a feature clearly needs them and can explain why.
- Omit unreadable files and reports instead of estimating them.

## Avoided

- Sudo-based collection.
- Private APIs for consumer-facing claims.
- Automatic file deletion.
- Silent background scanning of personal folders.
- Silent background scanning of diagnostic report folders.
- Reading document contents for diagnostics.
- Uploading process, file, crash, or device data.
- Including raw crash stack traces or document contents in exported summaries.
- Claiming certainty when macOS only exposes a partial signal.

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
- Presenting private-sensor readings as product truth.
