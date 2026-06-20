#!/bin/bash
# RPE Harness - Install Script

set -e

TARGET_DIR=$1
MODULES=${2:-"all"}

if [ -z "$TARGET_DIR" ]; then
  echo "Uso: $0 <target-dir> [modules]"
  echo "Módulos: all, rules, agents, commands, hooks, skills, mcp"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Instalando RPE Harness em $TARGET_DIR..."

install_module() {
  local module="$1"
  case "$module" in
    rules)
      mkdir -p "$TARGET_DIR/.cursor/rules"
      cp "$ROOT_DIR/.cursor/rules/"*.mdc "$TARGET_DIR/.cursor/rules/"
      ;;
    agents)
      mkdir -p "$TARGET_DIR/.cursor/agents"
      cp -r "$ROOT_DIR/.cursor/agents/"* "$TARGET_DIR/.cursor/agents/"
      ;;
    commands)
      mkdir -p "$TARGET_DIR/.cursor/commands"
      cp -r "$ROOT_DIR/.cursor/commands/"* "$TARGET_DIR/.cursor/commands/"
      ;;
    hooks)
      mkdir -p "$TARGET_DIR/.cursor/hooks"
      cp -r "$ROOT_DIR/.cursor/hooks/"* "$TARGET_DIR/.cursor/hooks/"
      cp "$ROOT_DIR/.cursor/hooks.json" "$TARGET_DIR/.cursor/"
      chmod +x "$TARGET_DIR/.cursor/hooks/"*/*.sh 2>/dev/null || true
      ;;
    skills)
      mkdir -p "$TARGET_DIR/.cursor/skills"
      cp -r "$ROOT_DIR/.cursor/skills/"* "$TARGET_DIR/.cursor/skills/"
      ;;
    mcp)
      if [ ! -f "$TARGET_DIR/.cursor/mcp.json" ]; then
        cp "$ROOT_DIR/.cursor/mcp.json.example" "$TARGET_DIR/.cursor/mcp.json"
        echo "ℹ️  mcp.json criado a partir do template. Configure variáveis de ambiente."
      else
        echo "ℹ️  mcp.json já existe — não sobrescrito."
      fi
      ;;
  esac
}

if [ "$MODULES" = "all" ]; then
  for mod in rules agents commands hooks skills mcp; do
    install_module "$mod"
  done
  cp "$ROOT_DIR/agents.md" "$TARGET_DIR/"
  mkdir -p "$TARGET_DIR/.cursor"
  cp "$ROOT_DIR/.cursor/scratchpad.template.md" "$TARGET_DIR/.cursor/scratchpad.template.md"
  if [ ! -f "$TARGET_DIR/.cursor/scratchpad.md" ]; then
    cp "$ROOT_DIR/.cursor/scratchpad.template.md" "$TARGET_DIR/.cursor/scratchpad.md"
  fi
else
  IFS=',' read -ra MOD_LIST <<< "$MODULES"
  for mod in "${MOD_LIST[@]}"; do
    install_module "$(echo "$mod" | xargs)"
  done
fi

echo "✅ Harness instalado com sucesso!"
