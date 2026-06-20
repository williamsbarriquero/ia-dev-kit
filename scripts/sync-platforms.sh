#!/bin/bash
# RPE Harness — orquestrador multi-IDE

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RPE_SYNC_PY="${KIT_ROOT}/scripts/lib/rpe_sync.py"

TARGET_DIR=""
PLATFORMS="cursor,copilot,claude,antigravity"
DRY_RUN=""

usage() {
  echo "Uso: $0 <target-dir> [--platforms=cursor,copilot,claude,antigravity] [--dry-run]"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

TARGET_DIR="$1"
shift

while [ $# -gt 0 ]; do
  case "$1" in
    --platforms=*)
      PLATFORMS="${1#*=}"
      ;;
    --dry-run)
      DRY_RUN="--dry-run"
      ;;
    *)
      echo "Opção desconhecida: $1"
      usage
      ;;
  esac
  shift
done

echo "🔄 Sincronizando RPE Harness para ${TARGET_DIR}"
echo "   Plataformas: ${PLATFORMS}"

python3 "${RPE_SYNC_PY}" "${TARGET_DIR}" --platforms="${PLATFORMS}" ${DRY_RUN} --command=all

echo "✅ Sync concluído."
