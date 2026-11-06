#!/bin/bash
# RPE Harness para Claude Code - atualização de um projeto já instalado.
# Roda a partir do clone do kit: atualiza o clone e reinstala com as stacks registradas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(dirname "$SCRIPT_DIR")"
KIT_REPO="$(dirname "$CLAUDE_ROOT")"
HARNESS_PY="$SCRIPT_DIR/lib/harness.py"

NO_PULL=false
HAS_STACK_FLAG=false
TARGET="."
ARGS=()

usage() {
  cat <<EOF
Uso: $0 [--no-pull] [--java|--go|--node|--react|--stack LIST|--all-stacks] [--skip-bun] [projeto-alvo]

Sem flags de stack, reutiliza as stacks de <alvo>/.claude/harness-stacks.json.
Arquivos que saíram do kit são removidos do alvo; AGENTS.md, CLAUDE.md e settings do usuário são preservados.
EOF
  exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull) NO_PULL=true; shift ;;
    --java|--go|--node|--react|--all-stacks) ARGS+=("$1"); HAS_STACK_FLAG=true; shift ;;
    --stack)
      [ -z "${2:-}" ] && usage
      ARGS+=(--stack "$2"); HAS_STACK_FLAG=true; shift 2 ;;
    --skip-bun) ARGS+=("$1"); shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Opção desconhecida: $1" >&2; usage ;;
    *) TARGET="$1"; shift ;;
  esac
done

[ -d "$TARGET" ] || { echo "Erro: diretório alvo não existe: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
STATE_FILE="$TARGET/.claude/harness-stacks.json"

if [ "$NO_PULL" = false ]; then
  if git -C "$KIT_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "🔄 Atualizando o kit em $KIT_REPO..."
    git -C "$KIT_REPO" pull --ff-only || echo "⚠️  git pull falhou; seguindo com a versão local do kit."
  fi
fi

if [ "$HAS_STACK_FLAG" = false ]; then
  if PARSED="$(python3 "$HARNESS_PY" read-stacks "$STATE_FILE" 2>/dev/null)"; then
    MODE="$(echo "$PARSED" | sed -n '1p')"
    STACKS="$(echo "$PARSED" | sed -n '2p')"
    if [ "$MODE" = "explicit" ] && [ -n "$STACKS" ]; then
      ARGS+=(--stack "$STACKS")
    else
      ARGS+=(--all-stacks)
    fi
    echo "📦 Stacks registradas: ${STACKS:-todas} (modo: $MODE)"
  else
    echo "ℹ️  $STATE_FILE ausente: instalando todas as stacks."
    ARGS+=(--all-stacks)
  fi
fi

# ${ARGS[@]+...} evita 'unbound variable' do bash 3.2 com array vazio e set -u.
exec bash "$SCRIPT_DIR/install.sh" ${ARGS[@]+"${ARGS[@]}"} "$TARGET"
