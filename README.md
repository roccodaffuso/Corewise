<p align="center">
  <img src="docs/assets/corewise-app-icon.png" width="112" height="112" alt="Corewise app icon">
</p>

<h1 align="center">Corewise</h1>

<p align="center">
  Understand what your Mac is doing, without giving up your data.
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-1f6feb?style=flat-square">
  <img alt="Swift 5.9+" src="https://img.shields.io/badge/Swift-5.9%2B-f05138?style=flat-square">
  <img alt="License MPL-2.0" src="https://img.shields.io/badge/License-MPL--2.0-7d5fff?style=flat-square">
  <img alt="Local only" src="https://img.shields.io/badge/Data-local_only-2db8bd?style=flat-square">
  <img alt="Beta status" src="https://img.shields.io/badge/Status-public_beta_in_preparation-d29922?style=flat-square">
</p>

Corewise is a local-first macOS diagnostic utility for understanding performance, storage, battery, startup activity, thermal state, and recurring app issues. It leads with observable signals, explains their limits, and never claims that one number represents the health of your Mac.

No account. No backend. No analytics. No automatic cleanup.

> [!IMPORTANT]
> Corewise is currently available publicly as source code. A signed and notarized release candidate exists locally, but no binary has been published yet. Do not treat GitHub's automatic “Source code” archives as installable app downloads.

## What Corewise does

- **Focused Check** observes supported local signals when a Mac feels slow, hot, battery-hungry, or full, then returns a cautious explanation and one useful next step.
- **Performance** separates CPU activity, memory context, swap, and live process evidence instead of presenting duplicate rankings.
- **AI Workloads** attributes supported local tools such as Codex, Claude, Cursor, and Ollama while keeping app footprint, related local work, and shared hosts separate.
- **Storage** shows startup-volume headroom and can perform a read-only analysis after one optional Full Disk Access grant or a user-selected folder scope.
- **System diagnostics** cover safe battery basics, launch plist inventory, high-level thermal state, and user-selected crash report patterns where macOS exposes reliable data.
- **Local reports** copy a plain-language Summary or Markdown report without uploading files, stack traces, prompts, or project details.

Corewise deliberately avoids health scores, process killing, automatic deletion, private sensor APIs, hidden folder scans, and claims of exact parity with Activity Monitor.

## Install today: build from source

Requirements:

- macOS 14 Sonoma or newer
- Xcode 15 or newer, or compatible Xcode Command Line Tools
- Git

```sh
git clone https://github.com/roccodaffuso/Corewise.git
cd Corewise
script/build_and_run.sh
```

The script builds and signs a local development bundle at `dist/Corewise.app`, then opens it. Full Disk Access is not required to run Corewise; it is optional and used only when you explicitly start Full Storage Analysis.

For the signed DMG workflow, Homebrew option, Gatekeeper requirements, and update strategy, see [Installation and distribution](docs/INSTALLATION.md).

## Privacy and safety model

Corewise reads supported diagnostics on the Mac where it is running. It has no network client, telemetry SDK, account system, payment flow, or remote database.

Every diagnostic source is classified as:

- **Live** — read from a supported local macOS source.
- **Planned** — intentionally not implemented yet.
- **Unavailable** — not currently exposed with enough reliability.
- **Avoided** — intentionally excluded for safety, privacy, or product integrity.

Storage and crash-report details require an explicit user action. Corewise does not upload diagnostic data or perform destructive remediation. Read the full [safety and privacy model](docs/SAFETY_PRIVACY.md) and [data-source matrix](docs/DATA_SOURCES.md).

## Development

Corewise is a dependency-free Swift Package Manager application targeting macOS 14+.

```sh
swift build
swift test
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
script/build_and_run.sh --verify
script/package_release.sh preview
# Requires a validated notarytool Keychain profile:
script/package_release.sh release --notary-profile corewise-notary
```

The app icon is reproducible from repository-owned drawing code:

```sh
swift script/generate_app_icon.swift
```

Useful project documents:

- [Product principles](PRODUCT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Current project status](docs/PROJECT_STATUS.md)
- [Design system](docs/DESIGN_SYSTEM.md)
- [Roadmap](docs/ROADMAP.md)
- [Decision log](docs/DECISIONS.md)

## Contributing

Issues and focused pull requests are welcome while the public beta is being prepared. Read [Contributing](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) before participating. Please keep changes narrow, preserve the local-first and non-destructive constraints, and never attach diagnostic reports containing usernames, personal paths, process arguments, prompts, or private file contents.

Found a reproducible problem? [Report an issue](https://github.com/roccodaffuso/Corewise/issues/new/choose). Security vulnerabilities belong in the [private reporting channel](SECURITY.md), not in a public issue. The issue link is also available in Corewise under **Settings → General → Project & Support**.

Before proposing a new diagnostic, document its public macOS source, failure mode, privacy boundary, and user-facing wording.

## License

Corewise source code is licensed under the [Mozilla Public License 2.0](LICENSE). MPL-2.0 uses file-level copyleft: modified Corewise source files distributed outside an organization remain available under MPL-2.0, while separate files can use other licenses. The Corewise name and logo are covered separately by the [trademark policy](TRADEMARKS.md).

Source files carry machine-readable `SPDX-License-Identifier: MPL-2.0` notices. Public binaries include the complete license and a link to the corresponding source repository.

## Project status

Corewise is under active beta development. The permanent identity is `Corewise`, `dev.corewise.Corewise`, and `corewise.dev`. Completing clean-account QA and validating the exact notarized beta artifact remain explicit gates before the first public binary.
