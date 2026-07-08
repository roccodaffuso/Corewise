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

## Status Language

Use these user-facing data badges:

- `Live`: read from the current Mac during this session.
- `Mock`: realistic placeholder used to shape the MVP.
- `Planned`: not implemented yet, but planned through safe APIs or read-only review.
- `Unavailable`: not safely available in the MVP.

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

## Chart Rules

- Charts should answer one question quickly.
- Use horizontal bars for process and offender rankings.
- Use compact breakdown charts for storage.
- Keep unit labels visible.
- Avoid random colors; use status colors.
- In narrow windows, prioritize readable labels over dense plotting.

## Copy Rules

- Explain behavior in plain language.
- Prefer "review", "inspect", "check", and "open" over action-heavy wording.
- Do not imply a value is real unless it is marked `Live`.
- Do not make unsupported claims about performance, battery service, thermal sensors, or system power.
