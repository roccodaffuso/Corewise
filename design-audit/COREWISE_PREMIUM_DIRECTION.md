# Corewise Premium Design Direction

## Executive thesis

Corewise should become a **signal-first Mac utility**: Raycast-level craft, Apple-native behavior, and progressive diagnostic depth.

The first screen must answer one question in under ten seconds:

> Is my Mac okay, and what deserves my attention right now?

Everything else should be available one deliberate step deeper. Premium quality will come from hierarchy, restraint, responsiveness, keyboard fluency, and consistent state behavior—not from adding more glass, gradients, cards, or decorative charts.

## Audit evidence

Current visual evidence: `design-audit/01-overview-current.png` at a 980 × 732 point window.

### What already works

- Calm, non-alarmist tone.
- Clear macOS sidebar structure.
- Semantic colors are restrained.
- Real local data appears before permissions and provenance.
- Typography and spacing are broadly consistent.
- Settings already uses a separate native window.

### Structural problems

1. **Coverage is visually mistaken for health.** The 67% ring is the dominant object even though it measures available data, not Mac condition.
2. **Everything becomes a card.** Hero, signals, charts, metrics, findings, actions, permissions, and source notes repeatedly use similar rounded material containers.
3. **The first viewport has weak prioritization.** Seven equal tiles require the user to interpret CPU, memory, processes, storage, battery, and thermal state independently.
4. **Material is used in the content layer.** Repeated translucent surfaces flatten hierarchy instead of creating depth.
5. **The sidebar spends too much space on descriptions.** Two-line navigation rows make an eight-item hierarchy feel heavier than it is.
6. **Secondary metadata competes with the answer.** `Live`, `Score Planned`, coverage, timestamps, sources, statuses, and explanations are often visible simultaneously.
7. **The visual language is competent but generic.** It resembles a polished dashboard rather than a distinctive Mac instrument.

### Evidence limits

- Overview was captured and visually inspected.
- Performance and Storage could not be captured because macOS Accessibility control was unavailable in the audit environment.
- Their structural assessment is therefore based on the current SwiftUI composition, not on screenshot-only evidence.
- Contrast, keyboard focus, VoiceOver order, Reduce Transparency, and resizing still require hands-on QA.

## Reference synthesis

### Raycast 2.0 — craft and interaction anchor

Borrow:

- One dominant task or answer per surface.
- Dense, calm rows instead of repeated cards.
- Contextual action bars and keyboard hints.
- Deep dark surfaces with precise tonal separation.
- Liquid Glass used selectively around controls and navigation.
- Native window, popover, settings, focus, and hover behavior.

Do not copy:

- Launcher topology as-is.
- Raycast red as the Corewise brand color.
- Floating-window behavior that conflicts with a persistent diagnostic workspace.

### Apple macOS / Tahoe — platform anchor

Borrow:

- Liquid Glass only as a functional navigation/control layer.
- Solid or standard-material content surfaces.
- Resizable layouts, collapsible sidebar, system accent behavior, keyboard support.
- Clear separation between content, controls, and transient UI.

### DaisyDisk and iStat Menus — diagnostic anchor

Borrow:

- One glanceable storage answer before scan depth.
- Explicit transition from overview to analysis.
- Compact data density and strong numeric scanning.
- Customizable depth without forcing every user into expert telemetry.

## Three possible lanes

### A. Signal Command Center — recommended

Raycast-like hierarchy applied to a persistent Mac diagnostic workspace.

- Dark-first, system-adaptive graphite environment.
- Compact sidebar grouped by intent.
- A single `Mac status` answer at the top.
- Ranked live signals presented as rows, not tiles.
- Contextual action strip and optional command palette.
- Electric teal as the signature accent; semantic colors remain state-only.

Strength: most distinctive and aligned with the requested Raycast reference.

Risk: can become too launcher-like if every action becomes a command.

### B. Native Observatory

A quieter Apple-first interpretation with more open space and fewer custom visual treatments.

- System materials and standard controls dominate.
- Larger narrative status area.
- More breathing room, fewer visible metrics.
- Detail appears through inspectors, disclosure groups, and native tables.

Strength: timeless, accessible, and highly credible.

Risk: may feel like a polished System Settings pane rather than a unique product.

### C. Precision Console

A denser expert mode influenced by iStat Menus and professional monitoring tools.

- Compact numeric rails, sparklines, tables, and comparison columns.
- Less prose in the first layer.
- High information density and configurable views.

Strength: powerful for technical users and repeated use.

Risk: weakens the promise of explaining Mac health clearly to non-experts.

## Chosen direction

Use a deliberate hybrid:

- **70% Signal Command Center** for hierarchy and product identity.
- **20% Native Observatory** for platform behavior and reassurance.
- **10% Precision Console** inside Performance and advanced detail views only.

Working name for the design language: **Corewise Signal System**.

### Implemented visual correction — 2026-07-09

The first implementation proved the information architecture but felt too close to stock SwiftUI. The corrected layer keeps the Signal System structure and adds the missing product identity through adaptive graphite tones, a proprietary teal, the Corewise signal glyph, a restrained instrument grid, titles outside section surfaces, stronger numeric hierarchy, and instrument treatment limited to Status, Performance, Storage, and compact command surfaces. This supersedes both the old equal-card dashboard and the overly neutral first pass.

## Information architecture

### Primary

- Overview
- Performance
- Storage

### System

- Battery
- Startup
- Thermal
- App Issues

### Utility

- Report
- Settings

The sidebar should use group labels and one-line rows. Descriptions move into the selected page. It should be collapsible and narrower than the current two-line rail.

## Overview blueprint

### 1. Status rail

Replace the coverage hero with:

- `Your Mac looks normal` / `2 signals worth reviewing` / `Attention recommended`.
- One sentence explaining why.
- Last updated and data-confidence detail in a quiet secondary position.
- A compact disclosure for coverage rather than a dominant ring.

### 2. Now

Show only the three highest-value live rows:

- Performance pressure.
- Storage headroom.
- Battery or thermal condition, whichever is more relevant.

Each row contains label, plain-language state, one key value, a restrained microvisual, and a chevron into detail.

### 3. What is using resources

A compact two-column list:

- Top CPU processes.
- Top memory processes.

Use rows and bars, not framed cards. Show three items initially and expose the full table through Performance.

### 4. Recommended next step

At most one recommendation, only when supported by live data. Otherwise show a calm `Nothing needs action right now` state.

### 5. Trust detail

Sources, coverage, unavailable signals, and privacy boundaries remain accessible through a secondary `Data & privacy` disclosure or inspector.

## Performance blueprint

- Treat Performance as the expert flagship.
- Keep CPU / Memory as a segmented mode.
- Lead with one pressure summary and short history.
- Use a dense native table as the primary surface.
- Put explanations in a contextual inspector for the selected process.
- Keep swap ownership limitations visible without repeating them on every row.
- Support sorting, keyboard selection, and a compact filter/search field.

## Storage blueprint

- Start with one disk row: available space, headroom state, and one scan action.
- Explain Full Disk Access only when classification is requested.
- Treat scan states as a clear progression: Not scanned → Scanning → Results → Drilldown.
- Make category composition the visual centerpiece after a scan.
- Keep largest folders/files as navigable lists with Finder reveal.
- Separate permission education from the everyday storage view.

## Core visual system

### Color

- Strategy: restrained.
- Accent: precise electric teal, under 10% of the visible surface.
- Background: neutral graphite, not tinted dashboard gray.
- Content layers: solid tonal steps rather than many translucent cards.
- Semantic green, amber, and red appear only when a state earns them.
- Respect the user’s macOS accent color in standard navigation controls where possible.

### Typography

- SF Pro throughout the product.
- Monospaced digits or SF Mono only for numeric diagnostics and shortcuts.
- Compact scale: approximately 12 / 13 / 15 / 20 / 28 points.
- Reduce the number of simultaneous weights and tertiary labels.
- Prefer short state sentences over large marketing headings.

### Surfaces

- Liquid Glass: sidebar, toolbar, transient controls, popovers.
- Standard material or opaque tonal surfaces: content.
- Dividers and alignment should organize most content.
- Cards are reserved for true self-contained objects or actionable states.
- Avoid nested cards entirely.

### Shape

- Panels: 10–14 point radius.
- Rows: 8–10 point radius only for selection/hover states.
- Pills: statuses, shortcuts, compact filters.
- Shadows: rare; use tonal separation first.

### Motion

- 150–220 ms transitions.
- Crossfade or numeric interpolation for live values.
- Smooth expansion into diagnostic detail.
- No page-load choreography, bounce, glow loops, or constant pulsing.
- Full Reduce Motion alternative.

## Signature product behaviors

1. **Corewise Quick Actions** — a `⌘K` palette for navigation and safe actions such as opening Performance, starting a storage scan, or copying a report.
2. **Progressive diagnostic inspector** — selecting a signal or process reveals its meaning and safe next step without navigating through several cards.
3. **Calm state language** — the interface explicitly says when nothing needs action.
4. **Live confidence indicator** — freshness and source coverage are visible but quiet, never confused with health.
5. **Menu bar continuity** — the popover uses the same status sentence and ranked signals as Overview.

## Accessibility and resilience requirements

- WCAG AA contrast for text and controls.
- Never encode health through color alone.
- Full keyboard traversal, visible focus, and predictable table order.
- VoiceOver labels for values, trends, and charts.
- Reduce Motion, Reduce Transparency, and Increase Contrast support.
- Test light/dark appearance and system accent colors.
- Test 980-point minimum width, narrow split view, large window, and long localized strings.
- Loading uses stable skeleton/placeholder structure; no content jumps every refresh.

## Anti-goals

- No cleaner-style urgency or one-click repair.
- No sea of equal cards.
- No glass on every content container.
- No decorative gradients or glowing outlines.
- No health score until the scoring model is real.
- No raw terminal aesthetic.
- No hiding trust limitations merely to make the interface look cleaner.

## Implementation roadmap

### Phase 0 — visual specification

- Confirm the Signal Command Center lane.
- Produce high-fidelity Overview, Performance, and Storage references.
- Define tokens, component states, and resize behavior.

### Phase 1 — shell

- Redesign window chrome, toolbar, sidebar groups, selection, and content rail.
- Establish solid content surfaces and contextual glass.
- Add keyboard navigation and Quick Actions specification.

### Phase 2 — Overview north star

- Replace coverage hero with Mac status.
- Replace seven equal tiles with ranked signals.
- Introduce progressive trust detail and one supported next action.

### Phase 3 — flagship diagnostics

- Rebuild Performance around table + inspector.
- Rebuild Storage around disk state + scan progression + results.

### Phase 4 — system pages

- Apply the same summary/list/inspector grammar to Battery, Startup, Thermal, and App Issues.
- Turn Report into a document-native preview instead of another dashboard.

### Phase 5 — polish and QA

- Motion, keyboard shortcuts, hover/focus/disabled/loading/error states.
- Accessibility and localization checks.
- Narrow/wide window and light/dark screenshot regression pass.

## Success criteria

- A new user can state whether the Mac needs attention within ten seconds.
- The first viewport contains no more than three equally prominent diagnostic groups.
- Coverage cannot be mistaken for health.
- Every secondary metric is reachable without dominating the default view.
- Overview, menu bar, and section pages use the same state language.
- The interface remains readable with transparency reduced and contrast increased.
- Performance and Storage feel expert without making Overview intimidating.

## Sources

- Apple Human Interface Guidelines: Designing for macOS, Sidebars, Layout, and Materials.
- Raycast, “The New Raycast” and “A Technical Deep Dive Into the New Raycast,” May 2026.
- DaisyDisk user guide and macOS Tahoe update.
- iStat Menus 7 product documentation.
