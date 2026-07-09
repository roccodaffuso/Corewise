# Settings Plan

## Summary

Corewise should implement Settings as a native macOS settings window, not as another diagnostic page in the main sidebar. The main app stays focused on live diagnostics; Settings controls product behavior, privacy choices, display preferences, and optional future persistence.

The app now declares a SwiftUI `Settings` scene and uses a dedicated `SettingsView` with compact native tabs. Settings remains configuration, not diagnosis.

## Research Notes

- Apple documents SwiftUI `Settings` as the native scene type for app settings on macOS.
- Apple documents `SettingsLink` as the SwiftUI entry point for opening the Settings scene from app UI.
- Apple documents `@AppStorage` for simple persisted preferences backed by user defaults.
- Apple Design Resources provide macOS UI kits and system resources; Corewise should keep Settings visually native and compact instead of inventing a custom dashboard surface.
- The local macOS SwiftUI patterns guidance recommends a dedicated `Settings` scene, separate settings root view, simple rows, `@AppStorage` for persisted preferences, and tabs/sections instead of deep push navigation.

References:

- Apple Developer Documentation: `Settings` scene: https://developer.apple.com/documentation/swiftui/settings
- Apple Developer Documentation: `SettingsLink`: https://developer.apple.com/documentation/swiftui/settingslink
- Apple Developer Documentation: `AppStorage`: https://developer.apple.com/documentation/swiftui/appstorage
- Apple Design Resources: https://developer.apple.com/design/resources/

## Product Decision

Settings belongs in the macOS app menu / Settings window, not in the Corewise diagnostic sidebar.

Reason:

- The sidebar is for diagnostic workflows: Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Report.
- Settings is configuration, not diagnosis.
- A separate Settings scene matches macOS expectations and avoids making the main app feel like a generic admin dashboard.

## Current State

Implemented:

- `CorewiseApp` declares `Settings { SettingsView() }`.
- `SettingsView` lives in its own view file.
- Settings uses a compact `TabView` with native `Form`, `Section`, `Picker`, and `Toggle` controls.
- Settings contains General, Privacy & Data, Performance, Report, and Menu Bar tabs.

Planned:

- Launch at login only if implemented through safe user-visible macOS APIs.
- Refresh interval only if refresh behavior becomes deliberately configurable.
- Remember selected folders only after security-scoped bookmark consent is designed.

Avoided:

- No Settings destination in the diagnostic sidebar.
- No account, backend, telemetry, tracking, or cloud configuration.
- No setting that enables automatic cleanup, deletion, process killing, or broad background scans.

## Proposed Structure

Implemented first version:

1. General
2. Privacy & Data
3. Performance
4. Report
5. Menu Bar

Settings uses a small macOS utility window footprint and avoids deep navigation.

## Implemented Preference Keys

- `settings.performance.defaultFocus`: `"cpu"` by default.
- `settings.report.defaultFormat`: `"summary"` by default.
- `settings.report.includeStorageScan`: `true` by default.
- `settings.report.includeCrashSummary`: `true` by default.
- `settings.menuBar.showCPU`: `true` by default.
- `settings.menuBar.showMemory`: `true` by default.
- `settings.menuBar.showSwap`: `true` by default.
- `settings.menuBar.showTopCPU`: `true` by default.
- `settings.menuBar.showTopMemory`: `true` by default.

## General

Purpose: lightweight app behavior.

Possible preferences:

- Show menu bar monitor: not implemented; the menu bar extra remains present in this version.
- Refresh interval: planned until refresh behavior is deliberately configurable.
- Launch at login: planned only if implemented through safe user-visible macOS APIs.
- Appearance: avoided for now unless there is a strong reason; Corewise should follow system appearance.

Default stance:

- Keep this tab sparse.
- Do not add preferences just to fill space.

## Privacy & Data

Purpose: make Corewise's trust model visible and controllable.

Content:

- Local-first statement: no account, backend, tracking, or telemetry.
- Explanation of automatic reads: CPU, memory, processes, storage volume, battery basics, thermal state, launch plist metadata.
- Explanation of user-selected reads: storage folders and crash reports.
- Explanation of avoided reads: private sensors, sudo-only paths, automatic personal-folder scans, automatic cleanup.

Possible controls:

- Clear session scan results: planned; clears only in-memory selected-folder/report state.
- Remember selected folders: planned and off by default; requires explicit security-scoped bookmark design before implementation.

Avoided:

- Any broad "scan my Mac automatically" toggle.
- Any setting that grants or implies durable access without explicit consent.

## Performance

Purpose: let users tune how performance diagnostics are displayed, not how data is collected.

Possible preferences:

- Default Performance tab: implemented as CPU or Memory.
- Show system/root processes: planned; default should be visible because hiding them can reduce trust.
- Highlight this app: implemented behavior can remain always on; a setting is probably unnecessary.
- High CPU threshold for explanations: planned only if users need it.

Avoided:

- Do not add "optimize", "kill heavy apps", or automatic remediation controls.
- Do not expose internal sampler details unless they are useful and understandable.

## Report

Purpose: control local report formatting and privacy.

Possible preferences:

- Default report format: implemented as Summary or Markdown.
- Include full paths in copied report: planned, default off unless the user explicitly enables it.
- Include selected storage scan summary: implemented, default on if a scan exists.
- Include crash report summary: implemented, default on if reports were manually selected, but never includes stack traces or raw report bodies.

Avoided:

- No automatic file save.
- No upload.
- No raw crash body, stack trace, binary images, or document contents.

## Menu Bar

Purpose: configure the lightweight monitor without turning it into a second dashboard.

Possible preferences:

- Show CPU in menu bar popover: implemented.
- Show memory in menu bar popover: implemented.
- Show swap in menu bar popover: implemented.
- Show top CPU process row: implemented.
- Show top memory process row: implemented.
- Keep popover compact: always on.
- Open Corewise from menu bar: implemented behavior should remain.

Avoided:

- Do not add full tables or diagnostic report export inside the menu bar extra.
- Do not duplicate the main app.

## Implementation Guidance

Implementation status:

- Keep `Settings` scene in `CorewiseApp`.
- Keep `SettingsView` out of `DashboardViews.swift` in a dedicated settings view file.
- Use `@AppStorage` only for real user preferences.
- Use `SettingsLink` from small entry points only if needed later, such as menu bar or Data Access copy.
- Keep settings rows simple: label, short explanatory text, control.
- Prefer system controls: `Toggle`, `Picker`, `Stepper`, `Button`, and `Form`.
- Avoid custom card-heavy settings UI.
- Document every persistent setting in this file and in `ARCHITECTURE.md`.

## Documentation Updates Required When Implemented

- `README.md`: add a short Settings note under Product Workflows only after settings have meaningful controls.
- `docs/ARCHITECTURE.md`: document `Settings` scene and any `@AppStorage` keys.
- `docs/DESIGN_SYSTEM.md`: keep Settings compact, native, and separate from diagnostic pages.
- `docs/SAFETY_PRIVACY.md`: document any preference that affects data access, persistence, or export content.
- `docs/DATA_SOURCES.md`: update only if a setting changes whether a data source is read or persisted.
- `docs/DECISIONS.md`: keep the decision that Settings is not a dashboard section.

## Success Criteria

- Settings opens through the native macOS Settings command.
- Settings does not appear as a diagnostic sidebar item.
- Every setting has a visible user benefit.
- Every persisted setting uses a documented `@AppStorage` key.
- No setting weakens the local-first, no-tracking, no-cleanup stance.
- No setting triggers broad scans, deletion, process termination, or private API reads.
