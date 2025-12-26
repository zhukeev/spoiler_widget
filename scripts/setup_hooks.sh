#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

chmod +x "$repo_root/.githooks/pre-commit"
git -C "$repo_root" config core.hooksPath .githooks
echo "Git hooks installed at .githooks"
