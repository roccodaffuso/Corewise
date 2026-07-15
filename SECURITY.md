# Security policy

## Supported versions

Security fixes are applied to the latest published Corewise release and the current `main` branch. Development snapshots and older prereleases may not receive separate fixes.

## Report a vulnerability privately

Do not open a public issue for a suspected vulnerability or attach sensitive diagnostics to an issue.

Use GitHub's private vulnerability reporting form:

https://github.com/roccodaffuso/Corewise/security/advisories/new

Include only the minimum information needed to reproduce the problem:

- affected Corewise version and macOS version;
- expected and observed behavior;
- safe reproduction steps;
- impact and any known mitigation.

Do not include passwords, tokens, private keys, prompts, personal files, full crash reports, or unrelated diagnostic exports. The maintainer will acknowledge a report on a best-effort basis, investigate privately, and coordinate disclosure after a fix or mitigation is available.

## Security boundaries

Corewise is local-first and intentionally has no account, backend, analytics, payment flow, remote database, automatic updater, destructive cleanup, or process-kill feature. Optional Full Disk Access is used only for a user-started read-only storage analysis.
