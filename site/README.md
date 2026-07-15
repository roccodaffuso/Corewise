# corewise.dev deployment

The site is static and deploys through `.github/workflows/pages.yml`. The workflow stages `site/`, the repository-owned app icon, and the current public-safe Corewise screenshot into the GitHub Pages artifact.

Before enabling DNS, verify `corewise.dev` in the GitHub account and configure the custom domain in repository Settings → Pages. Then configure the DNS provider:

| Type | Name | Value |
| --- | --- | --- |
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |
| CNAME | `www` | `roccodaffuso.github.io` |

Do not use wildcard DNS records. After propagation, enable **Enforce HTTPS** and verify both `corewise.dev` and `www.corewise.dev` redirect to the canonical HTTPS address.

The beta download links intentionally target `v0.1.0-beta.2`. Do not deploy the public site before that release and its assets exist.
