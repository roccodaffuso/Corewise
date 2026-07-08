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

## Mock

- Several pages show realistic placeholders. These must be visibly labeled before the product is tested with non-build-team users.
- Mock values must never be written as if they came from the user's Mac.

## Planned Rules

- Add visible provenance badges for `Live`, `Mock`, and `Unavailable`.
- Add source and confidence notes to every metric row.
- Keep storage scanning read-only.
- Prefer opening Finder, System Settings, or vendor-owned tools for user action.
- Ask for permissions only when a feature clearly needs them and can explain why.

## Avoided

- Sudo-based collection.
- Private APIs for consumer-facing claims.
- Automatic file deletion.
- Silent background scanning of personal folders.
- Reading document contents for diagnostics.
- Uploading process, file, crash, or device data.
- Claiming certainty when macOS only exposes a partial signal.

## Action Policy

Allowed actions:

- Explain what a metric means.
- Open a relevant folder or settings pane when the user chooses.
- Suggest a manual review path.
- Show that a signal is unavailable.

Not allowed in the MVP:

- Deleting files.
- Emptying Trash.
- Removing launch agents or daemons.
- Killing processes automatically.
- Changing system settings automatically.
- Presenting private-sensor readings as product truth.
