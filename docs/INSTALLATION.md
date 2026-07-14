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
git clone https://github.com/roccodaffuso/CoreWise.git
cd CoreWise
script/build_and_run.sh
```

The generated application is placed at `dist/Corewise.app`. The local build script uses an available development signing identity and falls back to ad-hoc signing when necessary. That behavior is suitable for development only; it is not the public release-signing workflow.

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

- [ ] Select and add an OSI-approved source license.
- [ ] Freeze the canonical name, permanent bundle identifier, version, and copyright metadata.
- [ ] Confirm the repository and Git history contain no secrets, personal paths, signing material, or unlicensed assets.
- [ ] Build and test a universal Apple Silicon and Intel application bundle.
- [ ] Sign every executable with Developer ID Application, hardened runtime, and secure timestamp.
- [ ] Package the app in a DMG and submit it with `notarytool`.
- [ ] Review the notarization log and staple the accepted ticket.
- [ ] Verify with `codesign`, `spctl`, a clean user account, and a second physical Mac.
- [ ] Publish SHA-256 checksums and release notes with supported macOS versions and known limitations.
- [ ] Test the optional Full Disk Access return flow on the exact distribution-signed bundle identifier.

The existing development bundle is not a substitute for these gates: it currently allows Apple Development or ad-hoc signing and disables timestamping.
