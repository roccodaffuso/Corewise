<!-- SPDX-License-Identifier: MPL-2.0 -->

# Corewise site SEO audit

Date: 2026-07-15  
Scope: the single-page public product site in `site/`

## Current assessment

The site has a solid on-page foundation after the signal-field redesign: one descriptive H1, a focused title and description, canonical URL, complete social metadata, crawlable product copy, semantic sections, useful FAQ content, optimized primary imagery, and SoftwareApplication structured data linked to the project author.

The main current blocker is HTTPS. DNS resolves correctly to GitHub Pages, but GitHub has not yet issued the custom-domain certificate. Because `.dev` is HSTS-preloaded, browsers and crawlers require valid HTTPS before the site can be treated as production-ready.

## Implemented

- Primary intent: private Mac performance and AI workload monitor.
- One H1 and ordered H2 hierarchy.
- Self-referencing HTTPS canonical.
- Index/follow robots directive with large image previews allowed.
- `robots.txt` linking to `sitemap.xml`.
- XML sitemap containing the canonical homepage.
- Open Graph and Twitter metadata with descriptive image alternative text.
- SoftwareApplication, WebSite, and Person JSON-LD.
- Author link to `https://rodabuilds.com/`.
- Descriptive screenshot alternative text and explicit dimensions.
- Hero image reduced from roughly 2 MB to roughly 143 KB for page delivery.
- No analytics, cookies, third-party fonts, or client-side framework.
- Motion respects `prefers-reduced-motion` and pauses outside the viewport.

## Remaining release checks

1. Wait for GitHub certificate issuance and enable Enforce HTTPS.
2. Verify `http` to `https` and `www` to apex redirects.
3. Verify `https://corewise.dev/robots.txt` and `/sitemap.xml` return `200`.
4. Validate the public URL with Google Rich Results Test after HTTPS is live.
5. Add the domain to Google Search Console and submit `/sitemap.xml`.
6. Record the initial indexed-page and query baseline before adding more SEO pages.

## Content direction

The homepage should remain the authoritative product page for queries around Mac performance monitoring, local Mac diagnostics, and AI workload monitoring on macOS. Additional pages should be added only when Search Console or user questions reveal a distinct intent; avoid thin keyword variants and generic AI-generated blog content.
