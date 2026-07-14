# Settings Plan

## Summary

Corewise should implement Settings as a native macOS settings window, not as another diagnostic page in the main navigation. The main app stays focused on live diagnostics; Settings controls product behavior, privacy choices, display preferences, and optional future persistence.

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

Settings belongs in the macOS app menu / Settings window, with a small footer link below the Corewise diagnostic navigation.

Reason:

- The primary sidebar list is for diagnostic workflows: Overview, Battery, Storage, Performance, Startup, Thermal, App Issues, and Report.
- Settings is configuration, not diagnosis.
- A separate Settings scene matches macOS expectations and avoids making the main app feel like a generic admin dashboard.

## Current State

Implemented:

- `CorewiseApp` declares `Settings { SettingsView(store: store) }`; the store is observed only for live preview values.
- `SettingsView` lives in its own view file.
- Settings uses a native `TabView` with grouped `Form`, `Section`, `Picker`, `Toggle`, and `Stepper` controls, plus one functional live menu-bar layout preview.
- Settings contains General, Privacy & Data, Performance, Report, and Menu Bar tabs.
- Every pane now has a consistent title, purpose statement, and semantic icon so the window reads as a deliberate utility surface rather than an unfinished form.
- The sidebar footer exposes a small native `SettingsLink` row so Settings is discoverable without adding it as a diagnostic navigation item.

Planned:

- Launch at login only if implemented through safe user-visible macOS APIs.
- Refresh interval only if refresh behavior becomes deliberately configurable.
- Storage access controls remain outside Settings. Full Disk Access is granted in macOS System Settings; Folder Scope fallback has its own visible `Forget` path in Storage.

Avoided:

- No Settings destination in the diagnostic navigation list.
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
- `settings.menuBar.showAIWorkloads`: `true` by default.
- `settings.menuBar.showTopCPU`: `true` by default.
- `settings.menuBar.showTopMemory`: `true` by default.
- `settings.menuBar.processRowCount`: `3` by default, normalized to `1...5`.

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

- Clear session scan results: planned; clears only in-memory Folder Scope/report state and never revokes Full Disk Access.
- Full Disk Access: not a Settings toggle. Corewise opens macOS System Settings and checks likely access from Storage.
- Folder Scope fallback: remembered only after explicit folder choice and revocable from Storage, not configured as a generic Settings preference.

Avoided:

- Any broad "scan my Mac automatically" Settings toggle.
- Any setting that grants or implies durable access without explicit consent.

## Performance

Purpose: let users tune how performance diagnostics are displayed, not how data is collected.

Possible preferences:

- Default Performance tab: implemented as CPU, Memory, or AI Workloads.
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
- Show top CPU rows: implemented.
- Show top memory rows: implemented.
- Show AI Workloads: implemented with local app footprint, current CPU, related local work, and the cloud-coverage boundary.
- Rows per list: implemented from one to five for AI Workloads, Top CPU, and Top Memory.
- Restore the menu bar layout defaults: implemented as an explicit local action.
- Keep popover compact: always on.
- Open Corewise from menu bar: implemented behavior should remain.
- Open Settings directly from the menu bar monitor: implemented as `Customize`.

Avoided:

- Do not add full tables or diagnostic report export inside the menu bar extra.
- Do not duplicate the main app.

## Implementation Guidance

Implementation status:

- Keep `Settings` scene in `CorewiseApp`.
- Keep `SettingsView` out of `DashboardViews.swift` in a dedicated settings view file.
- Use `@AppStorage` only for real user preferences.
- Use `SettingsLink` only from small entry points, currently the sidebar footer below the diagnostic navigation.
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

- Settings opens through the native macOS Settings command and the sidebar footer link.
- Settings does not appear as a diagnostic navigation item.
- Every setting has a visible user benefit.
- Every persisted setting uses a documented `@AppStorage` key.
- No setting weakens the local-first, no-tracking, no-cleanup stance.
- No setting triggers broad scans, deletion, process termination, or private API reads.
