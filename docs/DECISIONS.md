# Decision Log

## 2026-07-08: Corewise Is Local-First

Decision: Corewise has no account, backend, analytics, or tracking in the MVP.

Reason: The product promise depends on trust and calm local diagnostics.

## 2026-07-08: No Destructive MVP Actions

Decision: Corewise may explain and point to manual review paths, but it must not delete files, empty Trash, remove startup items, kill processes, or change settings automatically.

Reason: The app should not behave like an aggressive cleaner utility.

## 2026-07-08: Mock Data Must Be Declared

Decision: Mock values are allowed for UI/product scaffolding, but every metric must be labeled by data mode and confidence.

Reason: The current app mixes live CPU/RAM signals with broad mock diagnostic pages; hiding that would undermine trust.

## 2026-07-08: Live Performance Uses Public macOS Signals

Decision: CPU, RAM, and process rankings use public macOS process and VM information where available.

Reason: Performance is the first useful real diagnostic surface and can be collected locally without private APIs.

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

Decision: Corewise uses an explicit `DataMode` model field for `Live`, `Mock`, `Planned`, and `Unavailable` instead of inferring provenance from source or confidence strings.

Reason: The user must be able to tell immediately whether a value is real, scaffolded, planned, or intentionally unavailable.

## 2026-07-08: Storage Collector Is Read-Only And Omit-Unknown

Decision: Storage reads startup volume capacity and selected known paths only. Missing, absent, or unreadable folders are omitted instead of estimated.

Reason: It is safer to show fewer real values than to fill the UI with plausible but false storage diagnostics.

## 2026-07-08: Battery Collector Reads Only Safe Basics

Decision: Battery reads charge, power source, and charging state from IOKit power-source APIs. Cycle count, maximum capacity, and condition stay unavailable until Corewise has a safe documented source.

Reason: Battery trust depends on not inventing health details or implying service status without macOS-backed evidence.
