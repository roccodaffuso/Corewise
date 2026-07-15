![Corewise — local-first macOS diagnostics](https://raw.githubusercontent.com/roccodaffuso/Corewise/main/docs/assets/corewise-social-preview.jpg)

# Corewise 0.1.0 beta 2

Corewise is a free, open-source macOS 14+ utility for understanding performance, storage, and attributable local AI workloads without uploading diagnostics.

**[Download the signed and notarized universal DMG](https://github.com/roccodaffuso/Corewise/releases/download/v0.1.0-beta.2/Corewise-0.1.0-universal.dmg)**

## What you can explore

- **Focused Check** — observe supported signals when your Mac feels slow, hot, battery-hungry, or full.
- **Performance** — inspect CPU, memory context, swap, and live process evidence as distinct views.
- **AI Workloads** — separate attributable app footprint, related local work, and shared hosts for supported tools such as Codex, Claude, Cursor, and Ollama.
- **Storage** — see startup-volume headroom and start an explicit read-only analysis with optional reusable Full Disk Access.
- **Local reports** — copy a cautious summary or Markdown report without uploading diagnostic data.

<table>
  <tr>
    <td width="50%"><img src="https://raw.githubusercontent.com/roccodaffuso/Corewise/main/docs/assets/corewise-overview.png" alt="Corewise Overview"></td>
    <td width="50%"><img src="https://raw.githubusercontent.com/roccodaffuso/Corewise/main/docs/assets/corewise-ai-workloads.png" alt="Corewise AI Workloads"></td>
  </tr>
</table>

## Beta 2 fix

`⌘K` now reliably places keyboard focus in Quick Actions search before keyboard routing begins.

## Privacy and limits

- No account, telemetry, backend, analytics, or network collection.
- Full Disk Access is optional and used only for a user-started read-only Storage analysis.
- AI Workloads observes attributable local processes only. Cloud activity and logical agent counts are outside coverage.
- Corewise does not kill processes, delete files, or claim that one number represents Mac health.

## Install

1. Download `Corewise-0.1.0-universal.dmg` below.
2. Open the DMG and drag Corewise into Applications.
3. Open Corewise normally. The app is signed with Developer ID and notarized by Apple.

SHA-256:

```text
00444d9577db1b4708ab9ae6aa7a50bb55340b30bd5d978df2187ecb4d184389
```

[Website](https://corewise.dev) · [Source](https://github.com/roccodaffuso/Corewise) · [MPL-2.0](https://github.com/roccodaffuso/Corewise/blob/main/LICENSE) · [Security](https://github.com/roccodaffuso/Corewise/security/policy) · [Report an issue](https://github.com/roccodaffuso/Corewise/issues/new/choose)
