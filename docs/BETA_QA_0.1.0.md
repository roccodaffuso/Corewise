# Corewise 0.1.0 beta QA

Last updated: 2026-07-15

## Candidate under test

- Release: `v0.1.0-beta.2` (Draft prerelease)
- Application: `0.1.0 (3)`
- Status: current candidate, not yet public
- Commit: `5d810de384d8e8726ec027c1f1f35f79045e3d4f`
- Bundle identifier: `dev.corewise.Corewise`
- Artifact: `Corewise-0.1.0-universal.dmg`
- SHA-256: `00444d9577db1b4708ab9ae6aa7a50bb55340b30bd5d978df2187ecb4d184389`
- Apple notarization submission: `52df1d9c-5ca7-40f5-8f29-82c800a1f687` (`Accepted`)

The superseded `v0.1.0-beta.1` build 2 passed artifact validation but must not be published because keyboard QA found that Quick Actions did not reliably focus search. Beta.2 contains the minimal focus correction and was rebuilt, resigned, notarized, stapled, and validated from the merged fix commit.

## Completed evidence

### Automated and artifact validation

- 124 Swift tests pass.
- Strict concurrency with warnings as errors passes.
- The public-release audit, shell syntax checks, workflow parsing, bundle verification, and `git diff --check` pass.
- The DMG has a valid stapled notarization ticket and passes Gatekeeper as `Notarized Developer ID`.
- The mounted app passes strict Developer ID signature verification with hardened runtime and a secure timestamp.
- The application is universal (`arm64` and `x86_64`), targets macOS 14+, and contains `LICENSE.txt` and canonical `SourceCode.txt` notices.
- GitHub Actions run [29404942676](https://github.com/roccodaffuso/Corewise/actions/runs/29404942676) validated the exact beta.2 Draft Release asset and checksum on both `macos-26` ARM64 and `macos-26-intel`.

### Physical Mac validation

The exact beta.2 notarized DMG was mounted and copied to `/Applications/Corewise.app` on the primary Apple Silicon Mac.

- Gatekeeper accepted the installed application.
- First launch opened normally with no permission prompt.
- Overview loaded live signals at 1180×800.
- Settings opened and rendered the General and Menu Bar panes, including canonical GitHub, issue, license, and privacy surfaces.
- The menu bar monitor opened at 344 points wide and showed the enabled CPU, memory, swap, AI Workloads, Top CPU, and Top Memory sections.
- AI Workloads observed supported Codex and Claude processes and kept cloud activity outside local attribution.
- Quick Actions passed the release regression check: `⌘K` focused the `Search Corewise Quick Actions` text field, typing `AI Workloads` and pressing Return opened Performance, and Escape removed the overlay.
- Storage opened without Full Disk Access, showed startup-volume capacity, and offered one-time Full Disk Access without prompting for individual folders.
- Full Disk Access was previously granted to the distribution-signed beta.1 with the same `dev.corewise.Corewise` identity and unchanged Storage code, detected after relaunch, and reused without folder selection. A complete read-only analysis traversed all 11 curated scopes, reported real file/folder/time counters, finished with zero inaccessible scopes, and exposed category, largest-file, and largest-folder results.
- Resetting that grant and relaunching returned Storage to the access-required state without presenting the previous in-memory result as current.
- Storage rendered correctly in Light mode at the 980×680 minimum. Dark mode and 1180×800 were restored after the reversible check.

## Manual gates still open

- Create or use a separate clean local macOS account and repeat DMG open, drag-to-Applications, and first launch.
- Complete the remaining keyboard-only and VoiceOver/Accessibility Inspector review.
- Verify Reduce Motion, Reduce Transparency, Increase Contrast, and 1440×900.
- Confirm one external installation before stable promotion.
- Keep the public beta available for at least seven days with no blocking issue, data loss, or Gatekeeper false positive before promoting the same artifact to `v0.1.0`.

The absence of a second physical Mac is not an architecture blocker for the beta because the exact artifact passed clean GitHub-hosted ARM64 and Intel validation. It remains documented as a physical-device coverage limitation.
