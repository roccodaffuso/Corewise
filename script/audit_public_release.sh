#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

required_files=(
  LICENSE
  TRADEMARKS.md
  CONTRIBUTING.md
  SECURITY.md
  CODE_OF_CONDUCT.md
  .github/PULL_REQUEST_TEMPLATE.md
  .github/ISSUE_TEMPLATE/bug_report.yml
  .github/ISSUE_TEMPLATE/feature_request.yml
  docs/PUBLIC_RELEASE_AUDIT.md
  Sources/Corewise/Resources/SourceCode.txt
  site/index.html
  site/styles.css
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "required public-release file is missing: $file"
done

if git grep -n -E 'com\.roccodaffuso\.Corewise|github\.com/roccodaffuso/CoreWise' -- . >/dev/null; then
  fail "legacy bundle or repository identity remains in the tracked tree"
fi

git grep -q 'dev.corewise.Corewise' -- script/build_and_run.sh script/package_release.sh script/validate_release_candidate.sh || fail "permanent bundle identifier is not enforced"
git grep -q 'https://github.com/roccodaffuso/Corewise' -- Sources/Corewise/Resources/SourceCode.txt || fail "source notice does not use the canonical repository"
git grep -q 'Copyright © 2026 Rocco D’Affuso' -- script/build_and_run.sh script/package_release.sh || fail "bundle copyright metadata is missing"

if grep -Eq '\.package\s*\(' Package.swift; then
  fail "Package.swift contains an undeclared third-party provenance obligation"
fi

sensitive_files="$(git ls-files | grep -Ei '(^|/)(\.env($|\.)|.*\.(p8|p12|pem|key|mobileprovision|provisionprofile)$|id_rsa($|\.)|credentials?($|\.)|secrets?($|\.))' || true)"
[[ -z "$sensitive_files" ]] || fail "tracked sensitive filenames detected"

if git grep -I -n -E '(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)' -- . >/dev/null; then
  fail "credential-shaped content detected in the tracked tree"
fi

if git grep -I -n '/Users/roccodaffuso' -- . >/dev/null; then
  fail "machine-specific personal path detected in the tracked tree"
fi

while IFS= read -r file; do
  grep -q 'SPDX-License-Identifier: MPL-2.0' "$file" || fail "missing MPL-2.0 SPDX notice: $file"
done < <(git ls-files '*.swift' '*.sh' '.github/workflows/*.yml' 'site/*.js' 'site/*.css' 'site/*.html')

printf 'Public release audit passed: identity, notices, dependency boundary, sensitive filenames, common credential markers, personal paths, and SPDX coverage.\n'
