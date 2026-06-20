#!/bin/bash
# RPE Harness — sync rules para Copilot, Claude Code e Antigravity

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TARGET="${1:?Uso: sync-rules.sh <target-dir> [--platforms=...] [--dry-run]}"
shift || true

python3 "${RPE_SYNC_PY}" "${TARGET}" "$@" --command=rules
