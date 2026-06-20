#!/bin/bash
# RPE Harness — funções compartilhadas

set -euo pipefail

RPE_KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RPE_SYNC_PY="${RPE_KIT_ROOT}/scripts/lib/rpe_sync.py"

rpe_log() {
  echo "$@"
}

rpe_run_sync() {
  local command="${1:-all}"
  shift || true
  python3 "${RPE_SYNC_PY}" "$@" "${command}"
}
