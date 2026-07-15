# Corewise installation and distribution

## Recommendation

Corewise should launch with one official install path:

1. A universal `Corewise.app` signed with **Developer ID Application**.
2. The app packaged in a signed and notarized **DMG**.
3. The DMG and its SHA-256 checksum attached to a versioned **GitHub Release**.
4. The same release linked from `corewise.dev` when the site is ready.

This gives normal Mac users a familiar drag-to-Applications flow, preserves the current direct-distribution architecture, and lets Gatekeeper verify the developer signature and Apple notarization. Apple recommends notarizing software distributed outside the Mac App Store and requires hardened runtime, a secure timestamp, and an appropriate Developer ID signature for the standard notarization path.

Official references:

- [Signing Mac software with Developer ID](https://developer.apple.com/developer-id/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Packaging Mac software for distribution](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

## Installation modes

| Mode | Intended user | Experience | Corewise decision |
| --- | --- | --- | --- |
| Signed and notarized DMG | Most users | Download, drag to Applications, open normally | **Primary release channel** |
| Homebrew Cask | Developers and terminal users | Install and upgrade with Homebrew | Add after the first stable notarized artifact |
| Build from source | Contributors and reviewers | Clone, compile, run a local development bundle | Available now; not the consumer path |
| Mac App Store | General Mac audience | Store install and automatic updates | Reassess later; not the first release channel |
| PKG installer | Apps with privileged or multi-location components | Guided installer | Not justified: Corewise is currently a self-contained app |
| Unsigned ZIP | Ad hoc testers | Manual extraction with Gatekeeper friction | Do not publish as an official release |

## Current installation from source

Until the first public binary exists:

```sh
git clone https://github.com/roccodaffuso/Corewise.git
cd Corewise
script/build_and_run.sh
```

The generated application is placed at `dist/Corewise.app`. The local build script uses an available development signing identity and falls back to ad-hoc signing when necessary. That behavior is suitable for development only; it is not the public release-signing workflow.

## DMG packaging

Corewise now has two explicit packaging modes:

```sh
# Universal Developer ID-signed preview; not notarized and never for publishing
script/package_release.sh preview

# Public artifact; requires a notarytool Keychain profile
script/package_release.sh release --notary-profile corewise-notary
```

Both modes build arm64 and x86_64 separately, merge the executable with `lipo`, assemble the app bundle, enable hardened runtime, add a secure timestamp, create a compressed DMG with an Applications shortcut, mount it again for inspection, and publish a SHA-256 checksum under `dist/releases/`.

### GitHub Actions validation

Pull requests run the Swift test suite and strict-concurrency build on clean ARM64 and Intel macOS runners. Release candidates use a separate workflow that downloads the exact DMG and checksum from a Draft or published GitHub Release, then verifies:

- SHA-256 and disk-image integrity;
- the stapled notarization ticket and Gatekeeper assessment;
- the mounted app's strict Developer ID signature and hardened runtime;
- bundle identifier, version, build number, minimum macOS version, and universal architectures;
- a non-interactive launch smoke test on both runner architectures.

The workflow intentionally receives no Apple signing or notarization secrets. Signing and notarization remain local until the release process has been audited further. Clean-user first launch and assistive-technology behavior still require manual macOS QA; the distribution-signed Full Disk Access grant/revoke flow has passed on the primary Mac.

`release` additionally submits the DMG to Apple's notary service, waits for acceptance, staples the ticket, validates it, and runs a Gatekeeper assessment. It fails before packaging if the notary profile is missing. Notarization credentials stay in the login Keychain and must never be committed.

Create the profile once with credentials from the Apple Developer account:

```sh
xcrun notarytool store-credentials corewise-notary
```

If Apple ID authentication is unavailable, use an App Store Connect **Team API Key**. Individual API keys do not support `notarytool`. Keep the downloaded `.p8` outside the repository with owner-only permissions, then store a validated Keychain profile:

```sh
xcrun notarytool store-credentials corewise-notary \
  --key ~/.private_keys/AuthKey_<KEY_ID>.p8 \
  --key-id <KEY_ID> \
  --issuer <ISSUER_ID> \
  --validate
```

Never commit the `.p8`, Key ID, Issuer ID, Apple ID, app-specific password, or Keychain export.

The preview filename contains `-preview` so it cannot be confused with a publishable artifact.

## Current notarization result

The `0.1.0 (3)` universal beta candidate was accepted by Apple's notary service on 2026-07-15. Submission `52df1d9c-5ca7-40f5-8f29-82c800a1f687` returned `Accepted`. The DMG ticket was stapled and validated, and local Gatekeeper assessment reported `Notarized Developer ID`.

- Public prerelease: `v0.1.0-beta.2`
- Source commit: `5d810de384d8e8726ec027c1f1f35f79045e3d4f`
- Artifact: `dist/releases/Corewise-0.1.0-universal.dmg`
- Architectures: `arm64`, `x86_64`
- SHA-256: `00444d9577db1b4708ab9ae6aa7a50bb55340b30bd5d978df2187ecb4d184389`
- Exact-artifact GitHub validation: ARM64 and Intel passed in [run 29404942676](https://github.com/roccodaffuso/Corewise/actions/runs/29404942676)

The public beta has the permanent `dev.corewise.Corewise` identity and bundled MPL/source notices. External feedback is collected through GitHub Issues. Any application change requires a new build number, a newly notarized beta, and repeat artifact validation.

## Planned user flow for the first beta

1. Open the latest Corewise release on GitHub or follow the verified link from `corewise.dev`.
2. Download `Corewise-<version>-universal.dmg` and the published checksum file.
3. Open the DMG and drag Corewise to Applications.
4. Open Corewise normally. Gatekeeper should recognize the Developer ID signature and notarization ticket.
5. Grant Full Disk Access only if Full Storage Analysis is wanted. All other supported diagnostics should remain usable without that optional permission.

The initial beta should use manual updates: users download a newer signed release when one is published. Corewise should not add a network updater merely to ship the first beta.

## Homebrew

Homebrew Cask can move a packaged `.app` into `/Applications` from a versioned DMG or ZIP. Its cask definition requires a version, SHA-256 checksum, download URL, name, description, homepage, and app artifact. See the official [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook).

Recommended sequence:

1. Publish and validate at least one signed, notarized, versioned DMG.
2. Add a small project-owned tap for early adopters if terminal installation is useful.
3. Submit to the official Homebrew Cask repository only after release URLs, versioning, and update cadence are stable.

Do not advertise a `brew install` command until the cask and release artifact actually exist.

## Why not the Mac App Store first

The Mac App Store requires App Sandbox. Corewise currently depends on broad local diagnostic visibility and an optional Full Disk Access workflow, so every collector and permission path would need to be revalidated under sandbox constraints. Direct distribution avoids forcing that architectural decision before the product and external-user workflows are stable.

The App Store remains a possible later channel if a sandbox-compatible product slice can preserve truthful diagnostics without private entitlements or reduced transparency about coverage.

## Release gates

Before publishing an installable Corewise beta:

- [x] License Corewise source under MPL-2.0 and include the license and source-repository notice in public bundles.
- [x] Freeze the canonical name, permanent bundle identifier, version, and copyright metadata.
- [x] Audit the repository and Git history for secrets, personal paths, signing material, and asset provenance; keep the report current before each public release.
- [x] Build and test a universal Apple Silicon and Intel application bundle.
- [x] Sign every executable with Developer ID Application, hardened runtime, and secure timestamp.
- [x] Submit the packaged DMG with `notarytool` using a Keychain profile.
- [x] Review the zero-issue notarization log and staple the accepted ticket.
- [x] Verify the release candidate locally with `codesign`, `stapler`, and `spctl`.
- [x] Validate the exact release asset and published checksum on clean ARM64 and Intel runners.
- [x] Validate installation, Gatekeeper, first launch, Settings, menu bar, Storage pre-consent, AI Workloads, Dark mode, Light mode, 980×680, and 1180×800 on the primary Mac.
- [ ] Repeat installation and first launch with a clean user account; obtain at least one external installation before stable promotion.
- [x] Publish the prerelease checksum and release notes with supported macOS versions and known limitations.
- [x] Test grant, detection, complete read-only analysis, revocation, and access-required return on the exact distribution-signed bundle identifier.

The existing development bundle is not a substitute for these gates: it currently allows Apple Development or ad-hoc signing and disables timestamping.
