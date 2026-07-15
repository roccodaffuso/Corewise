# Focused Diagnostics Completion Audit

Audit date: 2026-07-10

Authoritative specification: `docs/FOCUSED_DIAGNOSTICS_IMPLEMENTATION_PLAN.md`

This document distinguishes implemented behavior from evidence that still requires external users, physical battery conditions, assistive-technology inspection, or the final distribution signature. An item is not marked complete merely because nearby code exists.

## Requirement matrix

| Plan area | Status | Authoritative evidence |
| --- | --- | --- |
| Symptom-led launcher | Proven | `FocusedCheckLauncher`, runtime Overview smoke test, and intent/routing tests. |
| Active check lifecycle | Proven | `FocusedCheckSession`, `FocusedCheckTracker`, store-owned refresh task, missing-interval tracking, and store lifecycle tests. |
| Completed result hierarchy | Proven | Runtime result inspection shows headline, explanation, duration/freshness, evidence, one action, coverage, direct copy, and Start Another Check. |
| Storage Full routing | Proven | `FocusedCheckIntent.launchRoute`, Overview/Quick Actions/menu bar use the shared route, and routing tests. |
| One-time Storage consent | Proven | Dedicated FDA probe, activation recheck, remembered one-folder fallback, explicit rescan policy, and no folder-by-folder pre-consent probes. |
| Storage progress/cancellation | Proven | Real scope/file/folder/unreadable/elapsed progress, cooperative cancellation, bounded allocation, large home-folder runtime profile, and Storage tests. |
| Recent full-result reuse | Proven | Explicit Focused Check may reuse a completed Full Storage Analysis up to six hours; Folder Scope requires visible confirmation before a scan. |
| Bounded aggregation | Proven | 300 system points, 50 app/process aggregates, three published app groups, battery timestamp deduplication, and bounded-history tests. |
| Pure intent resolvers | Proven | Resolver is SwiftUI/collector independent; Slow, Hot, Battery, Storage, insufficient, unavailable, clear, review, and critical rules are unit-tested. |
| Conservative language | Proven | Tests reject causal, health-diagnosis, reclaimable, and safe-to-delete claims across all resolver families. |
| App grouping | Proven | Normalized bundle path plus user, typed fallback kind, current member PIDs, and collision tests. |
| Process interpretation | Proven | Typed families, expected contexts, observed persistence, safe review action, matched PIDs, and inspector runtime integration. |
| Performance evidence continuity | Proven | Runtime deep link opens Performance, shows no more than three check-level app groups, filters raw processes, and preserves separate CPU/Memory consoles. |
| Storage attribution/coverage | Proven | Exact owner/review model, distinct application-support handling, used/classified/outside/inaccessible values, and no deletion promise. |
| Report/clipboard | Proven | Summary and Markdown share the same result, redact the home path, expose local copy, and include duration/action/limitations. |
| Quick Actions/menu bar | Proven | Typed start/finish/cancel/copy descriptors, scan-driven Storage restriction, and shared store/route state. |
| Deterministic states | Proven in source | Preview fixtures cover idle, observing, insufficient, clear, review, critical, Hot, Battery, Storage access/scanning/failure/cancellation/result, empty Performance, disappeared process, dark mode, and long copy. |
| Accessibility implementation | Proven in source | Copy actions post an explicit accessibility announcement; charts expose a separate label and value with period/start/end/maximum/trend; static evidence is not exposed as a disabled button; interactive disclosure rows remain separate VoiceOver controls; Increase Contrast strengthens panel boundaries. |
| Localization infrastructure | Proven | `Localizable.xcstrings` contains 233 English-default entries, `defaultLocalization` is `en`, formatted diagnostic copy uses localized format strings, and `xcstringstool compile` passes. |
| CPU budget | Proven | Focused Check symbols average 0.0246% of one core in the recorded workflow profile. |
| Memory budget | Proven | Release peak reduced from approximately 1,416 MB to 156 MB; a roughly 900,000-file explicit scan remained at the same peak. |
| No new backend/network/private API/destructive action | Proven | Package has no dependencies; source audit finds no networking layer, process termination, file deletion, sudo collector, or new entitlement. |
| 8-12 external trigger-based sessions | Open — external | Requires recruited users and observed workflows; deterministic previews and local smoke tests are not substitutes. |
| Full manual visual/accessibility matrix | Open — manual | Light/dark, all three target sizes, keyboard-only, VoiceOver/Accessibility Inspector, Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color must be recorded on the release candidate. |
| Ten-minute Battery check on battery power | Open — physical condition | `pmset -g batt` currently reports AC Power and a charged internal battery. The gate requires five or more distinct real readings while disconnected from external power; AC gating is already unit-tested. |
| Final distribution-signed profile | Open — release artifact | The local development/ad-hoc signed bundles pass; `security find-identity -v -p codesigning` currently reports zero valid signing identities, so a distribution-signed candidate cannot yet be produced or profiled. |

## Automated gates

Passed on 2026-07-10:

- `swift test`: 112 tests, 6 suites.
- `swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors`.
- `script/build_and_run.sh --verify`.
- `xcrun xcstringstool compile Sources/Corewise/Resources/Localizable.xcstrings`.
- `git diff --check`.
- Signed runtime smoke test: Overview → Slow result → typed Performance deep link → CPU/Memory mode switch.

## Acceptance audit

- A relevant check is reachable directly from the first Overview viewport.
- Results answer what was observed, why it matters, and what to inspect next.
- Evidence is capped at three and the result carries one primary action.
- No health score, health diagnosis, causal claim, fake percentage, or removable-space estimate is introduced.
- Storage stays read-only, explicit after consent, and never falls back to repeated folder prompts.
- Battery remains unavailable or insufficient when power source, duration, or distinct readings are inadequate.
- Active and completed state is shared by Overview, Performance/Storage, Report, Quick Actions, and menu bar.
- All history is volatile and disappears when the app process exits.

The technical implementation is ready for external validation. The overall plan is not product-validated until the four open rows above have recorded evidence.
