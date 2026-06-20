#!/bin/bash
# RPE Harness — sync MCP config para Copilot e Claude Code

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TARGET="${1:?Uso: sync-mcp.sh <target-dir> [--platforms=...] [--dry-run]}"
shift || true

python3 "${RPE_SYNC_PY}" "${TARGET}" "$@" --command=mcp
