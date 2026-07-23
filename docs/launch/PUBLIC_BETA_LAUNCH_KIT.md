<!-- SPDX-License-Identifier: MPL-2.0 -->

# Corewise public beta launch kit

## Launch posture

This is a small builder-led beta launch, not a general-availability campaign. The goal is to reach a first group of macOS and local-AI users, earn useful feedback, and turn concrete problems into GitHub Issues.

- Primary destination: **[corewise.dev](https://corewise.dev)**
- Direct beta: **[Corewise 0.1.0 beta 2](https://github.com/roccodaffuso/Corewise/releases/tag/v0.1.0-beta.2)**
- Feedback: **[GitHub Issues](https://github.com/roccodaffuso/Corewise/issues/new/choose)**

## Canonical message

### One line

> Corewise is a free, open-source Mac signal console that explains local performance, storage, and AI workloads without uploading diagnostic data.

### Three proof points

1. **AI Workloads** observes supported local tools such as Codex, Claude, Cursor, and Ollama, separating the app footprint from related local work and shared hosts.
2. **Local by design** means no account, telemetry, or backend. Corewise does not read prompts, projects, process arguments, or working directories.
3. **Open source** means the code is public under MPL-2.0, while the official beta is signed, notarized, and available for macOS 14 or later.

### Language boundaries

Say:

- “observed local processes”;
- “attributable app footprint”;
- “related local work”;
- “no urgent live signals detected”;
- “free and open source.”

Do not say:

- “active agents” or “agent count”;
- “Corewise sees cloud usage”;
- “your Mac is healthy”;
- “Corewise diagnoses or fixes your Mac”;
- “100% private” without explaining the local-data boundary.

## Recommended launch sequence

1. Publish the X post from `@rodabuilds` with the Overview image. Put links in the first reply.
2. Publish the LinkedIn post with the AI Workloads image and the website link in the body or first comment.
3. The next day, share the transparent Reddit post in a relevant macOS community with the AI Workloads image. Check each community's self-promotion rules first.
4. Reply to every substantive question and convert reproducible defects or requests into GitHub Issues.
5. Two or three days later, publish a short builder follow-up about what early users noticed. Do not invent adoption numbers or testimonials.

## X / Twitter launch post

Use `corewise-launch-overview.jpg`.

```text
Activity Monitor can show what is using your Mac.

I wanted something that also explains what matters — without a fake health score or an aggressive “clean now” button.

So I built Corewise: a local-first signal console for macOS.

It covers performance, storage, thermal signals, startup activity, recurring app issues, and local AI workloads.

Free. Open source. Public beta.
```

First reply:

```text
Corewise runs locally, has no account or telemetry, and the official macOS 14+ beta is signed and notarized.

Try it: https://corewise.dev
Source + issues: https://github.com/roccodaffuso/Corewise
```

Optional second post with `corewise-launch-ai-workloads.jpg`:

```text
The part I wanted most: AI Workloads.

Corewise can show the local CPU and memory footprint attributable to supported tools such as Codex, Claude, Cursor, and Ollama.

App footprint, related local work, and shared hosts stay separate. Cloud activity and “agent counts” are deliberately outside coverage.
```

## LinkedIn launch post

Use `corewise-launch-ai-workloads.jpg`.

```text
I have released the public beta of Corewise, a free and open-source macOS diagnostic utility.

I built it around a simple frustration: system monitors expose a lot of numbers, but they rarely help explain which signals matter or what a safe next step looks like.

Corewise brings performance, storage, battery, thermal state, startup activity, and recurring app issues into one local signal console. Its most distinctive view is AI Workloads: it observes supported local tools such as Codex, Claude, Cursor, and Ollama, while keeping directly attributable app footprint, related local work, and shared hosts explicitly separate.

The privacy boundary is intentionally narrow:
• no account, telemetry, or backend;
• no prompt or project inspection;
• no process arguments or working-directory collection;
• no automatic cleanup or destructive action.

The source is available under MPL-2.0. The macOS 14+ beta is universal, signed, and notarized.

I am looking for practical feedback from people who use a Mac for development, creative work, or local AI tools — especially confusing results, missing context, and rough edges.

Website and beta: https://corewise.dev
Source and issues: https://github.com/roccodaffuso/Corewise
```

## LinkedIn Italian alternative

Use `corewise-launch-ai-workloads.jpg`.

```text
Ho pubblicato la beta di Corewise, un'app macOS gratuita e open source per capire meglio cosa sta usando le risorse del Mac.

L'idea nasce da un limite che sentivo usando i normali monitor di sistema: mostrano molti numeri, ma spesso non spiegano quali segnali contano davvero e quale sia il prossimo controllo sensato.

Corewise riunisce performance, storage, batteria, stato termico, elementi di avvio e problemi ricorrenti delle app. La parte più particolare è AI Workloads: osserva i processi locali attribuibili a strumenti supportati come Codex, Claude, Cursor e Ollama, separando footprint dell'app, lavoro locale correlato e host condivisi.

Tutto resta locale: niente account, telemetria o backend; niente lettura di prompt, progetti, argomenti dei processi o cartelle di lavoro; nessuna pulizia automatica.

Il codice è pubblico con licenza MPL-2.0. La beta per macOS 14+ è universale, firmata e notarizzata.

Cerco feedback concreto, soprattutto su risultati poco chiari, contesto mancante e problemi reali di utilizzo.

Sito e beta: https://corewise.dev
Codice e issue: https://github.com/roccodaffuso/Corewise
```

## Reddit post

Published on 2026-07-23 in [`r/MacOSApps`](https://www.reddit.com/r/MacOSApps/comments/1v4fqie/i_built_corewise_free_opensource_mac_monitor_for/) with the AI Workloads image. The immediate measurement baseline was 16 gross DMG downloads and 9 gross checksum downloads; release asset requests are not unique users or confirmed installations.

### Community choice

Checked on 2026-07-23:

- **Publish first in `r/MacOSApps`** with the `Utilities` flair. It accepts focused macOS app showcases and has an active open-source audience interested in local utilities and AI/system monitors.
- **Treat `r/MacApps` as the higher-reach follow-up**, not the first cold post. Its current rules require a verified email, an account older than seven days, at least 10 comment-karma points earned inside `r/MacApps`, and explicit acknowledgement of the community rules. Open-source titles use the `[OS]` prefix, self-promotion is limited to once per 30 days, and concise posts are preferred.
- `r/macOS` is secondary because developer promotion is limited to Saturday, 00:00–23:59 UTC.
- Do not publish identical posts across communities at the same time. Publish in `r/MacOSApps`, answer substantive comments, then adapt the evidence and wording for `r/MacApps` after meeting its participation gate.

Use `corewise-launch-ai-workloads.jpg`. Lead with the distinctive workload-attribution problem rather than a generic product announcement.

Title for `r/MacOSApps`:

```text
I built Corewise — a free, open-source Mac monitor for performance, storage, and local AI workloads
```

Title for a later eligible `r/MacApps` post:

```text
[OS] Corewise — a free Mac monitor for performance, storage, and local AI workloads
```

Body:

```text
Hi, I’m the developer of Corewise.

I use several AI tools on my Mac and wanted a clearer answer to a simple question: how much CPU and memory belongs to the app itself, and how much comes from builds, shells, and helper processes running underneath it?

That became AI Workloads in Corewise. It observes supported local tools such as Codex, Claude, Cursor, and Ollama, while keeping three things separate: the directly identified app footprint, related local work, and shared hosts that cannot be attributed safely. It reports local processes, not “agent counts,” and cloud activity stays outside its coverage.

The rest of the app brings performance, storage, battery, thermal state, startup activity, and recurring app issues into one native macOS signal console. It is not a process killer or automatic cleaner, and it does not claim that one score represents the health of your Mac.

Corewise has no account, backend, or telemetry. It does not inspect prompts, projects, process arguments, environments, or working directories. Full Storage Analysis is read-only and its broader permission is optional.

The public beta is free, open source under MPL-2.0, universal, Developer ID signed, and notarized for macOS 14+.

Website and download: https://corewise.dev
Source: https://github.com/roccodaffuso/Corewise

Full disclosure: AI coding tools were part of my development workflow. The source, tests, data boundaries, and release process are public so they can be inspected rather than taken on trust.

If you try it, I’d especially value feedback on AI attribution: does the separation between app footprint and related work match what you see, and is a local tool missing or misclassified?
```

## Short variants

### Mastodon / Bluesky

Use `corewise-launch-overview.jpg`.

```text
Corewise is now in public beta: a free, open-source Mac signal console for performance, storage, and supported local AI workloads.

No account, telemetry, backend, prompt inspection, or automatic cleanup. The macOS 14+ build is signed and notarized.

https://corewise.dev
```

### GitHub profile or pinned note

```text
Building Corewise — a local-first, open-source macOS signal console with explicit AI workload attribution. Public beta: https://corewise.dev
```

## Coordinated images

All assets are 1200×675 JPEGs designed for X, LinkedIn, Reddit, Mastodon, and Bluesky. They use only Corewise-owned screenshots and the existing signal-field visual language.

| Asset | Purpose |
| --- | --- |
| `assets/corewise-launch-overview.jpg` | Main product announcement and general link sharing. |
| `assets/corewise-launch-ai-workloads.jpg` | AI Workloads explanation and developer-focused posts. |
| `assets/corewise-launch-privacy-open-source.jpg` | Privacy, open-source, and trust-oriented posts. |

Regenerate them with:

```sh
swift script/generate_launch_assets.swift \
  docs/assets/corewise-overview.png \
  docs/assets/corewise-ai-workloads.png \
  docs/assets/corewise-storage.png \
  docs/launch/assets
```

## Reply bank

### “Does it monitor my prompts or projects?”

No. AI Workloads uses local process identity and topology. Corewise does not read prompts, project contents, process arguments, environments, or working directories.

### “Can it see cloud agents or token usage?”

No. Cloud activity is outside local process observation. Corewise intentionally reports supported local tools, not logical or cloud-agent counts.

### “Why does Storage ask for access?”

Startup-volume capacity needs no folder access. Detailed file analysis is read-only and requires explicit optional permission because macOS protects personal data.

### “Why MPL-2.0?”

MPL-2.0 keeps distributed modifications to existing Corewise source files public while allowing separate files and integrations to use compatible terms. The project name and logo remain outside the code license.

### “Is it safe to install?”

The official beta is a universal Developer ID build signed and notarized by Apple. The release page includes its SHA-256 checksum and the source is public for inspection.

## Small-launch success signals

Do not add telemetry for the launch. Use only public or volunteered signals:

- confirmed external installations;
- relevant GitHub stars or forks;
- actionable Issues rather than raw issue count;
- questions that reveal unclear messaging;
- one or more users who can complete install, first launch, AI Workloads, and optional Storage analysis.
