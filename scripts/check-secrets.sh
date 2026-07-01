#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

failed=0

check() {
  if [[ "$1" -ne 0 ]]; then
    failed=1
  fi
}

# Block staging .env files (except .env.example)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if [[ "$file" == .env.example ]]; then
      continue
    fi
    if [[ "$file" == .env || "$file" == .env.* ]]; then
      echo "ERROR: staged secret env file: $file"
      failed=1
    fi
  done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
fi

# Block common secret file patterns in working tree (staged or not)
for pattern in '*.pem' '*.key' '*.p12' 'credentials.json'; do
  matches=$(find . -path './build' -prune -o -path './.dart_tool' -prune -o -name "$pattern" -print 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    echo "ERROR: secret file pattern found: $pattern"
    echo "$matches"
    failed=1
  fi
done

# Scan tracked/staged text for obvious token leaks (exclude build artifacts)
scan_paths=(lib test web scripts docs docker .env.example pubspec.yaml pubspec.lock)
for path in "${scan_paths[@]}"; do
  [[ -e "$path" ]] || continue
  if grep -RInE 'Bearer eyJ[A-Za-z0-9_-]{10,}|password\s*=\s*["'"'"'][^"'"'"']+["'"'"']' "$path" 2>/dev/null; then
    echo "ERROR: possible hardcoded secret in $path"
    failed=1
  fi
done

if [[ "$failed" -eq 0 ]]; then
  echo "check-secrets: OK"
  exit 0
fi

echo "check-secrets: FAILED — review output above"
exit 1
