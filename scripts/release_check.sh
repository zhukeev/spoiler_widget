#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
local_home="$repo_root/.dart_tool_home"
mkdir -p "$local_home"

flutter_cmd=()
dart_cmd=()

local_flutter="$repo_root/.fvm/flutter_sdk/bin/flutter"
local_dart="$repo_root/.fvm/flutter_sdk/bin/dart"

if [[ -x "$local_flutter" && -x "$local_dart" ]]; then
  flutter_cmd=("$local_flutter")
  dart_cmd=("$local_dart")
elif command -v fvm >/dev/null 2>&1; then
  flutter_cmd=(fvm flutter)
  dart_cmd=(fvm dart)
else
  flutter_cmd=(flutter)
  dart_cmd=(dart)
fi

export HOME="$local_home"
export DART_DISABLE_TELEMETRY=1
export FLUTTER_SUPPRESS_ANALYTICS=true

"${dart_cmd[@]}" format --output=none --set-exit-if-changed .
"${flutter_cmd[@]}" pub get
"${flutter_cmd[@]}" analyze
(cd "$repo_root/example" && "${flutter_cmd[@]}" analyze)
"${flutter_cmd[@]}" test
"${flutter_cmd[@]}" test test/golden_test.dart
"${dart_cmd[@]}" pub publish --dry-run
