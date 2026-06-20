#!/bin/bash
# RPE Harness — sync hooks para Copilot, Claude Code e Antigravity

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TARGET="${1:?Uso: sync-hooks.sh <target-dir> [--platforms=...] [--dry-run]}"
shift || true

python3 "${RPE_SYNC_PY}" "${TARGET}" "$@" --command=hooks
