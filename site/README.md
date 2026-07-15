# corewise.dev deployment

The site is static and deploys through `.github/workflows/pages.yml`. The workflow stages `site/`, the repository-owned app icon, and the current public-safe Corewise screenshot into the GitHub Pages artifact.

GitHub Pages was deployed on 2026-07-15 and `corewise.dev` is configured as the custom domain. Complete the DNS cutover at the provider with:

| Type | Name | Value |
| --- | --- | --- |
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |
| CNAME | `www` | `roccodaffuso.github.io` |

Do not use wildcard DNS records. After propagation, enable **Enforce HTTPS** and verify both `corewise.dev` and `www.corewise.dev` redirect to the canonical HTTPS address.

The beta download links target the public `v0.1.0-beta.2` prerelease. After DNS propagation, enable **Enforce HTTPS** and verify the public download, checksum, canonical URL, and `www` redirect.
