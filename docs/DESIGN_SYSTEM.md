# Corewise Signal System

Last updated: 2026-07-10

## Product register

Corewise is a calm, precise, premium macOS diagnostic utility. Design serves the task: familiar native controls, fast scanning, honest source boundaries, and a recognizable instrument identity without decorative dashboard grammar.

The implemented mix is 70% Signal Command Center, 20% Native Observatory, and 10% Precision Console inside Performance.

## Semantic tokens

- `CorewiseVisual` uses an adaptive Corewise graphite environment, a proprietary teal accent, tonal surfaces, restrained highlights, and semantic state colors.
- `CorewiseLayout` uses a 4/8/12/16/20/24/32 spacing scale, 28-point page margins, 14-point content radius, 10-point control radius, and an 1180-point content rail.
- SF Pro/system typography is used throughout. Diagnostics use monospaced digits; paths and report text use the system monospaced face.
- No `caption2`, fixed 9-point labels, glow, gradient buttons, gradient text, or repeated glass cards.

## Surfaces and hierarchy

- Material is reserved for native chrome, the sidebar, and the transient Quick Actions overlay.
- The content backdrop uses a low-contrast dot field and two static ambient color fields. They create depth but never carry information or animate.
- Content uses solid adaptive tonal surfaces, dividers, alignment, and native tables. A subtle tonal gradient is reserved for true instrument surfaces such as Status Rail and Performance history.
- `CorewiseBrandGlyph` is the shared signal signature in sidebar, Status Rail, menu bar, and Quick Actions; it is not repeated as a decorative watermark.
- `OperationalSection` keeps its title outside the bounded surface so sections do not read as an equal grid of cards. Rows and explanations are not wrapped in nested cards.
- `PageHeader` establishes stronger title hierarchy and adapts to a compact inspector mode.
- Overview: status rail → three signal groups → top resource users → at most one action → data/privacy disclosure.
- Focused Check: one compact symptom control group in the Overview flow → one active observation surface → one result surface. It is not a sidebar destination and never becomes five decorative cards.
- Performance: pressure/history → CPU/Memory control → mode-specific native process table → mode-specific inspector. CPU and Memory must never be cosmetic aliases: their eligibility, columns, sort choices, supporting metrics, and explanations differ.
- Storage: volume headroom → scan state → results → privacy/source disclosure.
- Battery, Thermal, Startup, App Issues, and Report use page-specific native layouts rather than a generic diagnostic-card template.

Coverage describes available signal families and must never appear as Mac health. The approved clear wording is `No urgent live signals detected`; Corewise never upgrades that sentence to `Your Mac is healthy`.

## Interaction and accessibility

- `⌘K` opens in-window Quick Actions. Escape closes it; arrows move; Return runs.
- Sidebar, menu bar, and Quick Actions route through typed `DashboardRoute` values.
- Refresh retains visible content and table state; initial loading uses redacted skeletons.
- Process selections open an inspector. If a process disappears, its last sample remains visible and is explicitly marked stale.
- Storage cancellation discards partial data and preserves the last completed session.
- State always combines text, icon, and color. Icon-only controls retain textual labels.
- Charts expose trend summaries; progress exposes counts and scope rather than a false percentage.
- Focused evidence rows expose text, icon, severity, value, confidence, sample count, and an optional typed destination. Color is never the sole state indicator.
- Reduce Motion disables hover displacement and transient copied-state animation. Reduce Transparency removes ambient fields and replaces Quick Actions material with a solid system background.

## Copy and trust

- Prefer inspect, review, check, and open.
- Never suggest killing processes, deleting files, causal thermal attribution, exact Activity Monitor parity, or per-process swap ownership.
- Source, confidence, data mode, last update, and privacy boundaries remain available one layer below the immediate answer.
