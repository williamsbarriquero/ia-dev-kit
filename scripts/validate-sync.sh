#!/bin/bash
# RPE Harness - Sync Validator

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TMP_DIR="${KIT_ROOT}/.tmp/sync-validate-$$"
mkdir -p "${TMP_DIR}"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "🔍 Validando sync multi-IDE em ${TMP_DIR}..."

bash "${KIT_ROOT}/scripts/sync-platforms.sh" "${TMP_DIR}" --platforms=cursor,copilot,claude,antigravity

ERRORS=0

count_files() {
  find "$1" -type f 2>/dev/null | wc -l | tr -d ' '
}

EXPECTED_RULES=$(find "${KIT_ROOT}/.cursor/rules" -name "*.mdc" | wc -l | tr -d ' ')
EXPECTED_AGENTS=$(find "${KIT_ROOT}/.cursor/agents" -name "*.md" | wc -l | tr -d ' ')
EXPECTED_COMMANDS=$(find "${KIT_ROOT}/.cursor/commands" -name "*.md" | wc -l | tr -d ' ')
EXPECTED_SKILLS=$(find "${KIT_ROOT}/.cursor/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

GLOBAL_RULES=$(grep -l "alwaysApply: true" "${KIT_ROOT}/.cursor/rules/"*.mdc 2>/dev/null | wc -l | tr -d ' ')
CONTEXT_RULES=$(grep -l "^globs:" "${KIT_ROOT}/.cursor/rules/"*.mdc 2>/dev/null | wc -l | tr -d ' ')

# Cursor
if [ ! -d "${TMP_DIR}/.cursor/rules" ]; then
  echo "❌ .cursor/rules não gerado"
  ERRORS=$((ERRORS + 1))
fi

# Copilot
COPILOT_INSTRUCTIONS="${TMP_DIR}/.github/copilot-instructions.md"
if [ ! -f "${COPILOT_INSTRUCTIONS}" ]; then
  echo "❌ .github/copilot-instructions.md não gerado"
  ERRORS=$((ERRORS + 1))
fi

INSTRUCTIONS_COUNT=$(find "${TMP_DIR}/.github/instructions" -name "*.instructions.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "${INSTRUCTIONS_COUNT}" -lt "${CONTEXT_RULES}" ]; then
  echo "❌ instructions: esperado >= ${CONTEXT_RULES}, encontrado ${INSTRUCTIONS_COUNT}"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ instructions contextuais: ${INSTRUCTIONS_COUNT}"
fi

PROMPTS_COUNT=$(find "${TMP_DIR}/.github/prompts" -name "*.prompt.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "${PROMPTS_COUNT}" -ne "${EXPECTED_COMMANDS}" ]; then
  echo "❌ prompts: esperado ${EXPECTED_COMMANDS}, encontrado ${PROMPTS_COUNT}"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ prompts: ${PROMPTS_COUNT}"
fi

AGENTS_COPILOT=$(find "${TMP_DIR}/.github/agents" -name "*.agent.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "${AGENTS_COPILOT}" -ne "${EXPECTED_AGENTS}" ]; then
  echo "❌ agents copilot: esperado ${EXPECTED_AGENTS}, encontrado ${AGENTS_COPILOT}"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ agents copilot: ${AGENTS_COPILOT}"
fi

# Claude
if [ ! -f "${TMP_DIR}/CLAUDE.md" ]; then
  echo "❌ CLAUDE.md não gerado"
  ERRORS=$((ERRORS + 1))
fi

CLAUDE_RULES=$(find "${TMP_DIR}/.claude/rules" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "${CLAUDE_RULES}" -lt "${CONTEXT_RULES}" ]; then
  echo "❌ claude rules: esperado >= ${CONTEXT_RULES}, encontrado ${CLAUDE_RULES}"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ claude rules: ${CLAUDE_RULES}"
fi

# Antigravity
if [ ! -f "${TMP_DIR}/.agents/agents.md" ]; then
  echo "❌ .agents/agents.md não gerado"
  ERRORS=$((ERRORS + 1))
fi

WORKFLOWS=$(find "${TMP_DIR}/.agents/workflows" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "${WORKFLOWS}" -ne "${EXPECTED_COMMANDS}" ]; then
  echo "❌ workflows: esperado ${EXPECTED_COMMANDS}, encontrado ${WORKFLOWS}"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ workflows: ${WORKFLOWS}"
fi

# AGENTS.md universal
if [ ! -f "${TMP_DIR}/AGENTS.md" ]; then
  echo "❌ AGENTS.md não gerado"
  ERRORS=$((ERRORS + 1))
fi

# Hooks
if [ ! -d "${TMP_DIR}/scripts/ai-hooks" ]; then
  echo "❌ scripts/ai-hooks não gerado"
  ERRORS=$((ERRORS + 1))
fi

# Dry-run
echo "🔍 Testando dry-run..."
bash "${KIT_ROOT}/scripts/sync-platforms.sh" "${TMP_DIR}" --platforms=copilot --dry-run > /dev/null

if [ $ERRORS -gt 0 ]; then
  echo "⚠️ Sync validation falhou com ${ERRORS} erro(s)."
  exit 1
fi

echo "✨ Sync multi-IDE validado com sucesso."
