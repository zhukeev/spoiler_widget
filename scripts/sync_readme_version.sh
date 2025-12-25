#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pubspec="$repo_root/pubspec.yaml"
readme="$repo_root/README.md"

version=$(grep -E "^version:" "$pubspec" | head -n 1 | awk '{print $2}')
if [[ -z "$version" ]]; then
  echo "Unable to read version from $pubspec" >&2
  exit 1
fi

readme_version=$(
  awk '/spoiler_widget:[[:space:]]*\^/ {gsub(/[^0-9.]/, "", $2); print $2; exit}' "$readme"
)
if [[ -z "$readme_version" ]]; then
  echo "Unable to read dependency version from $readme" >&2
  exit 1
fi

if [[ "${1:-}" == "--check" ]]; then
  if [[ "$readme_version" != "$version" ]]; then
    echo "README version ($readme_version) does not match pubspec ($version)." >&2
    exit 1
  fi
  exit 0
fi

if [[ "$readme_version" != "$version" ]]; then
  perl -0pi -e 's/(spoiler_widget:\\s*\\^)[0-9.]+/$1'"$version"'/g' "$readme"
fi
