#!/bin/bash
# RPE Harness - Validator

echo "🔍 Validando integridade do RPE Harness..."

ERRORS=0

function check_dir() {
  if [ ! -d "$1" ]; then
    echo "❌ Diretório ausente: $1"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ Diretório encontrado: $1"
  fi
}

check_dir ".cursor/rules"
check_dir ".cursor/agents"
check_dir ".cursor/hooks"
check_dir ".cursor/skills"

if [ ! -f ".cursor/hooks.json" ]; then
  echo "❌ hooks.json ausente"
  ERRORS=$((ERRORS+1))
fi

if [ ! -f "agents.md" ]; then
  echo "❌ agents.md ausente"
  ERRORS=$((ERRORS+1))
fi

if [ $ERRORS -gt 0 ]; then
  echo "⚠️ Foram encontrados $ERRORS erros na estrutura do Harness."
  exit 1
else
  echo "✨ O RPE Harness está íntegro e pronto para uso."
  exit 0
fi
