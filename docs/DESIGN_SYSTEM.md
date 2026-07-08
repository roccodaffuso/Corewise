# Design System

## Summary

Corewise should feel like a serious Apple-native diagnostic utility: calm, precise, dense enough to be useful, and never alarmist.

## Visual Principles

- Use native SwiftUI controls, system materials, system colors, and SF Symbols.
- Keep cards purposeful: summary cards, metric cards, findings, actions, and data notes.
- Use semantic colors only for state: green good, blue info, amber warning, red critical.
- Pair color with labels and icons; never rely on color alone.
- Keep typography compact and readable in narrow macOS windows.
- Prefer calm density over marketing-style hero composition.
- Put operational live diagnostics before explanatory access panels in the first viewport.
- Do not use placeholder score states as the primary hero. The Overview hero must show a verifiable fact: live signals, coverage, and update time.
- Coverage numbers must count diagnostic signal families, not table rows such as individual processes or launch plist entries.
- Data provenance badges must stay single-line. If a panel is narrow, wrap the surrounding layout rather than compressing badge text vertically.
- Storage breakdown uses red for used space and green for available space. This is a storage-capacity convention, not a destructive-action cue.
- Performance pages should lead with summary pressure and a compact top list. Full process rows should hide long filesystem paths behind short context labels unless the user asks for raw detail.

## Status Language

Use these user-facing data badges:

- `Live`: read from the current Mac during this session.
- `Planned`: not implemented yet, but planned through safe APIs or read-only review.
- `Unavailable`: not safely available in the MVP.
- `Avoided`: intentionally excluded because the source or behavior would weaken the trust model.

Use these health states:

- `Good`: no action needed.
- `Info`: useful context, not a problem by itself.
- `Warning`: worth reviewing.
- `Critical`: important and should be reviewed carefully.

## Page Requirements

Every diagnostic page should include:

- Summary card.
- Metric grid or list.
- Findings.
- Safe actions.
- Data source note.
- Manual scan controls only where the user explicitly grants scope.

## Permission Controls

- Use calm labels such as `Choose Folder` and `Choose Reports`.
- Explain the scope before the picker opens.
- Do not present manual scans as required, urgent, or automatic.
- After a scan, keep `Live` badges tied to the selected folder/report source.

## Chart Rules

- Charts should answer one question quickly.
- Use tables for process diagnostics; use horizontal bars only for compact app-group summaries and storage offenders.
- Use compact breakdown charts for storage.
- Keep unit labels visible.
- Avoid random colors; use status colors.
- In narrow windows, prioritize readable labels over dense plotting.

## Copy Rules

- Explain behavior in plain language.
- Prefer "review", "inspect", "check", and "open" over action-heavy wording.
- Do not imply a value is real unless it is marked `Live`.
- Do not claim Activity Monitor exact parity; describe CPU, observed memory, footprint, RSS, VM memory, and swap by their actual sources.
- Do not make unsupported claims about performance, battery service, thermal sensors, or system power.
