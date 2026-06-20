#!/bin/bash
# RPE Harness - Validator

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🔍 Validando integridade do RPE Harness..."

ERRORS=0

function check_dir() {
  if [ ! -d "$1" ]; then
    echo "❌ Diretório ausente: $1"
    ERRORS=$((ERRORS + 1))
  else
    echo "✅ Diretório encontrado: $1"
  fi
}

function check_file() {
  if [ ! -f "$1" ]; then
    echo "❌ Arquivo ausente: $1"
    ERRORS=$((ERRORS + 1))
  else
    echo "✅ Arquivo encontrado: $1"
  fi
}

check_dir ".cursor/rules"
check_dir ".cursor/agents"
check_dir ".cursor/commands"
check_dir ".cursor/hooks"
check_dir ".cursor/skills"
check_file ".cursor/hooks.json"
check_file "agents.md"
check_file "scripts/sync-platforms.sh"
check_file "scripts/lib/rpe_sync.py"

# Frontmatter em rules
for rule in .cursor/rules/*.mdc; do
  if ! head -1 "$rule" | grep -q "^---$"; then
    echo "❌ Frontmatter ausente em: $rule"
    ERRORS=$((ERRORS + 1))
  fi
done

# Agents com readonly explícito
for agent in .cursor/agents/*.md; do
  if ! grep -q "^readonly:" "$agent"; then
    echo "❌ Campo readonly ausente em: $agent"
    ERRORS=$((ERRORS + 1))
  fi
done

# Skills: name = pasta pai
for skill_md in .cursor/skills/*/SKILL.md; do
  skill_dir=$(basename "$(dirname "$skill_md")")
  skill_name=$(grep -m1 "^name:" "$skill_md" | sed 's/name: *//' | tr -d '"')
  if [ "$skill_name" != "$skill_dir" ]; then
    echo "❌ Skill name '$skill_name' não corresponde à pasta '$skill_dir'"
    ERRORS=$((ERRORS + 1))
  fi
done

# Commands com passo numerado
for cmd in .cursor/commands/*.md; do
  if ! grep -qE "^[0-9]+\." "$cmd"; then
    echo "❌ Command sem passo numerado: $cmd"
    ERRORS=$((ERRORS + 1))
  fi
done

# Referências Cursor-only obsoletas
if grep -rq "core/004-interaction-standards" .cursor/agents templates 2>/dev/null; then
  echo "❌ Referência obsoleta core/004-interaction-standards encontrada"
  ERRORS=$((ERRORS + 1))
fi
if grep -rq "401-code-review" .cursor/commands 2>/dev/null; then
  echo "❌ Referência obsoleta 401-code-review encontrada"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
  echo "⚠️ Foram encontrados $ERRORS erros na estrutura do Harness."
  exit 1
else
  echo "✨ O RPE Harness está íntegro e pronto para uso."
  exit 0
fi
