# Settings Plan

## Summary

Corewise should implement Settings as a native macOS settings window, not as another diagnostic page in the main sidebar. The main app stays focused on live diagnostics; Settings controls product behavior, privacy choices, display preferences, and optional future persistence.

The current app already declares a SwiftUI `Settings` scene and a minimal `SettingsView`. This plan documents how to mature that surface without adding code in this task.

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
- `SettingsView` exists, but it is a placeholder form with local-first copy only.

Planned:

- Move Settings content into a dedicated view file when implementation begins.
- Replace the placeholder with a compact native settings window.
- Add only preferences that have a clear product effect.

Avoided:

- No Settings destination in the diagnostic sidebar.
- No account, backend, telemetry, tracking, or cloud configuration.
- No setting that enables automatic cleanup, deletion, process killing, or broad background scans.

## Proposed Structure

Use a compact `TabView` or sectioned `Form`, depending on final density.

Recommended first implementation:

1. General
2. Privacy & Data
3. Performance
4. Report
5. Menu Bar

Avoid deep navigation. Settings should feel like a small macOS utility window, roughly `460-560px` wide and `320-420px` tall unless content genuinely needs more space.

## General

Purpose: lightweight app behavior.

Possible preferences:

- Show menu bar monitor: `Live` if the menu bar extra can be toggled safely; otherwise planned.
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

- Default Performance tab: CPU or Memory.
- Show system/root processes: planned; default should be visible because hiding them can reduce trust.
- Highlight this app: implemented behavior can remain always on; a setting is probably unnecessary.
- High CPU threshold for explanations: planned only if users need it.

Avoided:

- Do not add "optimize", "kill heavy apps", or automatic remediation controls.
- Do not expose internal sampler details unless they are useful and understandable.

## Report

Purpose: control local report formatting and privacy.

Possible preferences:

- Default report format: Summary or Markdown.
- Include full paths in copied report: planned, default off unless the user explicitly enables it.
- Include selected storage scan summary: default on if a scan exists.
- Include crash report summary: default on if reports were manually selected, but never include stack traces or raw report bodies.

Avoided:

- No automatic file save.
- No upload.
- No raw crash body, stack trace, binary images, or document contents.

## Menu Bar

Purpose: configure the lightweight monitor without turning it into a second dashboard.

Possible preferences:

- Show CPU in menu bar label: planned.
- Show memory in menu bar label: planned.
- Keep popover compact: always on.
- Open Corewise from menu bar: implemented behavior should remain.

Avoided:

- Do not add full tables or diagnostic report export inside the menu bar extra.
- Do not duplicate the main app.

## Implementation Guidance

When coding begins:

- Keep `Settings` scene in `CorewiseApp`.
- Move `SettingsView` out of `DashboardViews.swift` into a dedicated settings view file.
- Use `@AppStorage` only for real user preferences.
- Use `SettingsLink` from small entry points if needed, such as menu bar or Data Access copy.
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
