#!/bin/bash
# RPE Harness - Install Script

set -euo pipefail

TARGET_DIR=""
PLATFORMS="cursor,copilot,claude,antigravity"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Uso: $0 <target-dir> [--platforms=cursor,copilot,claude,antigravity]"
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
    *)
      echo "Opção desconhecida: $1"
      usage
      ;;
  esac
  shift
done

echo "🚀 Instalando RPE Harness em ${TARGET_DIR}..."
echo "   Plataformas: ${PLATFORMS}"

mkdir -p "${TARGET_DIR}"

# Preservar overrides locais
if [ -f "${TARGET_DIR}/agents.override.md" ]; then
  echo "ℹ️  Preservando agents.override.md existente"
fi
if [ -f "${TARGET_DIR}/CLAUDE.local.md" ]; then
  echo "ℹ️  Preservando CLAUDE.local.md existente"
fi

bash "${KIT_ROOT}/scripts/sync-platforms.sh" "${TARGET_DIR}" --platforms="${PLATFORMS}"

echo "✅ Harness instalado com sucesso!"
