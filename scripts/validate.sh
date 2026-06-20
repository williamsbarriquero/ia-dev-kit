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
  model_line=$(grep -m1 "^model:" "$agent" || true)
  if echo "$model_line" | grep -qE '\[|\]'; then
    echo "❌ Campo model malformado em: $agent ($model_line)"
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

# Referências editor-agnósticas no SSOT (ver authoring-guide.md)
SSOT_CONTENT_DIRS=(".cursor/agents" ".cursor/commands" ".cursor/skills" ".cursor/rules" "templates")

check_ssot_pattern() {
  local pattern="$1"
  local message="$2"
  for dir in "${SSOT_CONTENT_DIRS[@]}"; do
    if [ -d "$dir" ] && grep -rqE "$pattern" "$dir" 2>/dev/null; then
      echo "❌ ${message}"
      grep -rnE "$pattern" "$dir" 2>/dev/null | head -5
      ERRORS=$((ERRORS + 1))
      return 0
    fi
  done
}

check_ssot_pattern '\.cursor/rules/' 'Referência Cursor-only: use nome simples (ex: interaction-standards.mdc), não caminho .cursor/rules/'
check_ssot_pattern 'rules/core/' 'Referência inválida: subdiretório rules/core/ não existe no SSOT'
check_ssot_pattern '@[a-zA-Z0-9_-]+\.md' 'Menção @ exclusiva do Cursor encontrada (ex: @rpe-developer.md)'
check_ssot_pattern '[0-9]{3}-[a-zA-Z0-9_-]+\.mdc' 'Referência com prefixo numérico obsoleto (ex: 401-code-review.mdc)'

# Regras referenciadas em backticks devem existir em .cursor/rules/
for dir in "${SSOT_CONTENT_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    if [ ! -f ".cursor/rules/${ref}" ]; then
      echo "❌ Regra referenciada não encontrada: ${ref}"
      ERRORS=$((ERRORS + 1))
    fi
  done < <(grep -rohE '`[a-zA-Z0-9_-]+\.mdc`' "$dir" 2>/dev/null | tr -d '`' | sort -u)
done

if [ $ERRORS -gt 0 ]; then
  echo "⚠️ Foram encontrados $ERRORS erros na estrutura do Harness."
  exit 1
else
  echo "✨ O RPE Harness está íntegro e pronto para uso."
  exit 0
fi
