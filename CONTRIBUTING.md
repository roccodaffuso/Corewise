# Contributing to Corewise

Thank you for helping make Corewise more trustworthy and useful. Focused bug reports and narrowly scoped pull requests are welcome.

By submitting a contribution, you agree that it is provided under the Mozilla Public License 2.0. Corewise does not currently require a Contributor License Agreement or Developer Certificate of Origin.

## Before opening an issue

- Search existing issues first.
- Use the provided bug or feature form.
- Remove usernames, personal paths, prompts, process arguments, crash bodies, file contents, and signing information.
- Report security vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Development setup

Corewise is a dependency-free Swift Package Manager application targeting macOS 14 or newer.

```sh
swift build
swift test
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
script/build_and_run.sh --verify
```

## Pull requests

- Keep each change focused on one problem.
- Explain the user-visible behavior and the evidence used to verify it.
- Add or update tests for behavior changes.
- Preserve local-only collection, cautious wording, public macOS APIs, and non-destructive behavior.
- Do not add networking, telemetry, accounts, private APIs, elevated helpers, automatic cleanup, or process termination without a separately accepted product and security decision.
- New diagnostic sources must document provenance, availability, failure behavior, privacy boundary, and user-facing limitations.
- Use neutral branch names such as `feature/*`, `fix/*`, and `release/*`.

Maintainers may ask for a smaller change when a pull request combines unrelated work.

## Release material

Never commit Developer ID private keys, certificates with private material, App Store Connect `.p8` files, notary credentials, provisioning profiles, personal diagnostic exports, or built release artifacts. Official binaries are produced through the documented release process.
