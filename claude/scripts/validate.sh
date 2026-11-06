#!/bin/bash
# RPE Harness para Claude Code - validação.
#   No kit:  bash claude/scripts/validate.sh
#   No alvo: bash .claude/rpe/validate.sh   (ou claude/scripts/validate.sh <alvo>)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_PY="$SCRIPT_DIR/lib/harness.py"
ERRORS=0
WARNINGS=0

err() { echo "❌ $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "⚠️  $*"; WARNINGS=$((WARNINGS + 1)); }
ok() { echo "✅ $*"; }

# shellcheck source=lib/stack-manifest.sh
source "$SCRIPT_DIR/lib/stack-manifest.sh"

if [ $# -ge 1 ]; then
  MODE=target
  ROOT="$(cd "$1" && pwd)"
elif [ "$(basename "$SCRIPT_DIR")" = "rpe" ] && [ "$(basename "$(dirname "$SCRIPT_DIR")")" = ".claude" ]; then
  MODE=target
  ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
  MODE=kit
  CLAUDE_ROOT="$(dirname "$SCRIPT_DIR")"
  ROOT="$CLAUDE_ROOT/kit"
fi

run_lint() {
  local base="$1" output line
  output="$(python3 "$HARNESS_PY" lint "$base" --mode "$MODE")"
  while IFS= read -r line; do
    case "$line" in
      ERROR*) err "${line#ERROR }" ;;
      WARN*) warn "${line#WARN  }" ;;
      INFO*) ok "${line#INFO  }" ;;
    esac
  done <<< "$output"
}

check_bun() {
  if command -v bun >/dev/null 2>&1; then
    ok "Bun $(bun --version)"
  else
    err "Bun ausente: os hooks do kit não rodam e os guards ficam inativos (https://bun.sh)"
  fi
}

validate_kit() {
  echo "🔍 Validando o kit-fonte em $ROOT"
  local dir file item stack
  for dir in rules agents skills knowledge hooks templates specs; do
    [ -d "$ROOT/$dir" ] || err "diretório ausente: kit/$dir"
  done
  for file in AGENTS.md CLAUDE.md settings.fragment.json mcp.json.example scratchpad.template.md specs/README.md; do
    [ -f "$ROOT/$file" ] || err "arquivo ausente: kit/$file"
  done
  [ -f "$CLAUDE_ROOT/VERSION" ] || err "arquivo ausente: claude/VERSION"

  # Manifesto e kit precisam bater nos dois sentidos.
  for item in "${HARNESS_CORE_RULES[@]}"; do [ -f "$ROOT/rules/$item.md" ] || err "manifesto cita rule inexistente: $item"; done
  for item in "${UNIVERSAL_SKILLS[@]}"; do [ -d "$ROOT/skills/$item" ] || err "manifesto cita skill inexistente: $item"; done
  for stack in "${ALL_STACKS[@]}"; do
    while IFS= read -r item; do [ -f "$ROOT/rules/$item.md" ] || err "manifesto ($stack) cita rule inexistente: $item"; done < <(stack_items RULES "$stack")
    while IFS= read -r item; do [ -d "$ROOT/skills/$item" ] || err "manifesto ($stack) cita skill inexistente: $item"; done < <(stack_items SKILLS "$stack")
    while IFS= read -r item; do [ -f "$ROOT/knowledge/$item" ] || err "manifesto ($stack) cita knowledge inexistente: $item"; done < <(stack_items KNOWLEDGE "$stack")
  done
  SELECTED_STACKS=("${ALL_STACKS[@]}")
  resolve_install_sets
  for file in "$ROOT"/rules/*.md; do
    array_contains "$(basename "$file" .md)" "${INSTALL_RULES[@]}" || err "rule fora do manifesto (nunca instalada): $(basename "$file")"
  done
  for dir in "$ROOT"/skills/*/; do
    array_contains "$(basename "$dir")" "${INSTALL_SKILLS[@]}" || err "skill fora do manifesto (nunca instalada): $(basename "$dir")"
  done

  run_lint "$ROOT"

  for file in "$CLAUDE_ROOT"/scripts/*.sh; do
    bash -n "$file" || err "sintaxe bash inválida: $file"
  done
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x "$CLAUDE_ROOT"/scripts/*.sh "$CLAUDE_ROOT"/scripts/lib/*.sh || err "shellcheck acusou problemas"
  else
    warn "shellcheck ausente: lint de shell não executado"
  fi

  check_bun
  if command -v bun >/dev/null 2>&1; then
    if (cd "$CLAUDE_ROOT" && bun test tests/hooks >/dev/null 2>&1); then
      ok "testes dos hooks (bun test tests/hooks)"
    else
      err "testes dos hooks falharam: rode 'cd claude && bun test tests/hooks'"
    fi
  fi
  if bash "$CLAUDE_ROOT/tests/install/install-smoke.sh" >/dev/null 2>&1; then
    ok "install/update/validate ponta a ponta (tests/install/install-smoke.sh)"
  else
    err "smoke do instalador falhou: rode 'bash claude/tests/install/install-smoke.sh'"
  fi
}

validate_target() {
  echo "🔍 Validando o harness instalado em $ROOT"
  local state="$ROOT/.claude/harness-stacks.json" parsed stacks_csv file item
  [ -d "$ROOT/.claude" ] || { err ".claude/ ausente: rode o install.sh"; return; }
  if parsed="$(python3 "$HARNESS_PY" read-stacks "$state" 2>/dev/null)"; then
    stacks_csv="$(echo "$parsed" | sed -n '2p')"
    IFS=',' read -ra SELECTED_STACKS <<< "${stacks_csv:-java,go,node,react}"
    ok "stacks instaladas: ${SELECTED_STACKS[*]}"
    resolve_install_sets
    for item in "${INSTALL_RULES[@]}"; do [ -f "$ROOT/.claude/rules/$item.md" ] || err "rule ausente: $item"; done
    for item in "${INSTALL_SKILLS[@]}"; do [ -f "$ROOT/.claude/skills/$item/SKILL.md" ] || err "skill ausente: $item"; done
    for item in "${INSTALL_KNOWLEDGE[@]}"; do [ -f "$ROOT/.claude/knowledge/$item" ] || err "knowledge ausente: $item"; done
  else
    err "$state ausente ou inválido"
  fi

  for file in .claude/templates/feature-spec.md .claude/templates/technical-spec.md .claude/scratchpad.template.md; do
    [ -f "$ROOT/$file" ] || err "arquivo ausente: $file"
  done

  if [ -f "$ROOT/AGENTS.md" ] || [ -f "$ROOT/agents.md" ]; then
    if grep -qs '_\[PREENCHER' "$ROOT/AGENTS.md" "$ROOT/agents.md"; then
      warn "AGENTS.md ainda tem _[PREENCHER]_: peça ao Claude para preencher o baseline"
    fi
  else
    err "AGENTS.md ausente"
  fi
  if grep -qiE '^@agents\.md$' "$ROOT/CLAUDE.md" 2>/dev/null; then
    ok "CLAUDE.md importa o baseline"
  else
    err "CLAUDE.md não importa @AGENTS.md: o Claude Code não lerá o baseline"
  fi
  grep -qxF ".rpe/" "$ROOT/.gitignore" 2>/dev/null || warn ".gitignore sem as entradas do harness (.rpe/, settings.local.json)"

  run_lint "$ROOT/.claude"
  check_bun
}

if [ "$MODE" = kit ]; then
  validate_kit
else
  validate_target
fi

echo ""
echo "Resultado: $ERRORS erro(s), $WARNINGS aviso(s)"
[ "$ERRORS" -eq 0 ]
