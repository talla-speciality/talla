#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d /private/tmp/talla-admin-model-checks.XXXXXX)"
trap 'rm -rf "$check_dir"' EXIT
swiftc -module-cache-path "$check_dir/cache" \
  "$project_root/Talla Admin/AdminModels.swift" \
  "$project_root/Talla Admin/AdminWorkspaceModels.swift" \
  "$project_root/tools/AdminWorkspaceModelChecks.swift" \
  -o "$check_dir/checks"
"$check_dir/checks"
