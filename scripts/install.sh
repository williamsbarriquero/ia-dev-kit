#!/bin/bash
# RPE Harness - Install Script

set -e

TARGET_DIR=$1
MODULES=$2

if [ -z "$TARGET_DIR" ]; then
  echo "Uso: $0 <target-dir> [modules]"
  exit 1
fi

echo "🚀 Instalando RPE Harness em $TARGET_DIR..."

mkdir -p "$TARGET_DIR/.cursor/rules"
mkdir -p "$TARGET_DIR/.cursor/agents"
mkdir -p "$TARGET_DIR/.cursor/commands"
mkdir -p "$TARGET_DIR/.cursor/hooks"
mkdir -p "$TARGET_DIR/.cursor/skills"

# Copiando regras
cp .cursor/rules/*.mdc "$TARGET_DIR/.cursor/rules/"
cp -r .cursor/agents/* "$TARGET_DIR/.cursor/agents/"
cp -r .cursor/commands/* "$TARGET_DIR/.cursor/commands/"
cp -r .cursor/hooks/* "$TARGET_DIR/.cursor/hooks/"
cp -r .cursor/skills/* "$TARGET_DIR/.cursor/skills/"
cp .cursor/hooks.json "$TARGET_DIR/.cursor/"
cp .cursor/mcp.json "$TARGET_DIR/.cursor/"
cp agents.md "$TARGET_DIR/"

echo "✅ Harness instalado com sucesso!"
