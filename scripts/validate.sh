#!/bin/bash
# RPE Harness - Validator

set -euo pipefail

echo "🔍 Validando integridade do RPE Harness..."

ERRORS=0
WARNINGS=0

check_dir() {
  if [ ! -d "$1" ]; then
    echo "❌ Diretório ausente: $1"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ Diretório encontrado: $1"
  fi
}

check_file() {
  if [ ! -f "$1" ]; then
    echo "❌ Arquivo ausente: $1"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ Arquivo encontrado: $1"
  fi
}

check_dir ".cursor/rules"
check_dir ".cursor/agents"
check_dir ".cursor/hooks"
check_dir ".cursor/skills"
check_dir ".cursor/commands"
check_file ".cursor/hooks.json"
check_file "agents.md"
check_file ".cursor/scratchpad.template.md"
check_file ".cursor/hooks/continuations/grind-loop.ts"
check_file ".cursor/mcp.json.example"

AGENT_COUNT=$(find .cursor/agents -name "*.md" | wc -l | xargs)
if [ "$AGENT_COUNT" -lt 10 ]; then
  echo "⚠️ Esperados ≥10 agentes, encontrados: $AGENT_COUNT"
  WARNINGS=$((WARNINGS+1))
else
  echo "✅ Agentes: $AGENT_COUNT"
fi

COMMAND_COUNT=$(find .cursor/commands -name "*.md" | wc -l | xargs)
echo "✅ Commands: $COMMAND_COUNT"

for script in .cursor/hooks/guards/*.sh .cursor/hooks/transforms/*.sh; do
  if [ -f "$script" ] && [ ! -x "$script" ]; then
    echo "⚠️ Script sem permissão de execução: $script"
    WARNINGS=$((WARNINGS+1))
  fi
done

if command -v bun >/dev/null 2>&1; then
  echo "✅ Bun disponível para grind-loop.ts"
else
  echo "⚠️ Bun não encontrado — grind-loop.ts pode falhar"
  WARNINGS=$((WARNINGS+1))
fi

if grep -q 'rules/core/' .cursor/agents/*.md 2>/dev/null; then
  echo "❌ Referências obsoletas a rules/core/ encontradas nos agentes"
  ERRORS=$((ERRORS+1))
fi

MCP_FILE=".cursor/mcp.json"
MCP_EXAMPLE=".cursor/mcp.json.example"

if [ -f "$MCP_FILE" ]; then
  if python3 -c "import json; json.load(open('$MCP_FILE'))" 2>/dev/null; then
    echo "✅ mcp.json é JSON válido"
  else
    echo "❌ mcp.json inválido"
    ERRORS=$((ERRORS+1))
  fi
elif [ -f "$MCP_EXAMPLE" ]; then
  if python3 -c "import json; json.load(open('$MCP_EXAMPLE'))" 2>/dev/null; then
    echo "✅ mcp.json.example é JSON válido (mcp.json local ausente — esperado)"
  else
    echo "❌ mcp.json.example inválido"
    ERRORS=$((ERRORS+1))
  fi
else
  echo "❌ Nem mcp.json nem mcp.json.example encontrados"
  ERRORS=$((ERRORS+1))
fi

if [ $ERRORS -gt 0 ]; then
  echo "⚠️ $ERRORS erro(s) e $WARNINGS aviso(s) encontrados."
  exit 1
else
  echo "✨ O RPE Harness está íntegro ($WARNINGS aviso(s))."
  exit 0
fi
