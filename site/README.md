# corewise.dev deployment

The site is static and deploys through `.github/workflows/pages.yml`. The workflow stages `site/`, the repository-owned app icon, and the current public-safe Corewise screenshot into the GitHub Pages artifact.

GitHub Pages was deployed on 2026-07-15 and `corewise.dev` is configured as the custom domain. The DNS provider now publishes:

| Type | Name | Value |
| --- | --- | --- |
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |
| CNAME | `www` | `roccodaffuso.github.io` |

No wildcard DNS records are used. The authoritative nameservers, Cloudflare, and Google resolve the GitHub Pages records; GitHub certificate issuance and HTTPS enforcement remain pending.

The beta download links target the public `v0.1.0-beta.2` prerelease. When GitHub finishes certificate issuance, enable **Enforce HTTPS** and verify the public download, checksum, canonical URL, and `www` redirect.

The landing page uses a dependency-free signal-field canvas, scroll-linked product depth, intersection reveals, and CSS-only workload flows. Motion pauses outside the viewport and follows `prefers-reduced-motion`. `robots.txt`, `sitemap.xml`, canonical metadata, social metadata, and SoftwareApplication structured data are shipped with the static site.
