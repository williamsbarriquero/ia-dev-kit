#!/bin/bash
# Teste de ponta a ponta do install/update/validate num projeto temporário.
# Uso: bash claude/tests/install/install-smoke.sh
set -euo pipefail

CLAUDE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
TARGET="$WORK/alvo"
FAILURES=0

pass() { echo "  ✅ $*"; }
fail() { echo "  ❌ $*"; FAILURES=$((FAILURES + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }
json() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print($2)" "$1"; }

echo "▶ Preparando projeto com configuração própria do usuário"
mkdir -p "$TARGET/.claude"
(cd "$TARGET" && git init -q)
printf '{"name":"alvo","scripts":{"test":"node -e \\"process.exit(0)\\""}}\n' > "$TARGET/package.json"
printf '# Projeto alvo\n\nInstruções do time.\n' > "$TARGET/CLAUDE.md"
cat > "$TARGET/.claude/settings.json" <<'EOF'
{
  "permissions": { "allow": ["Bash(npm test)"], "deny": ["Edit(**/.env)"] },
  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "echo usuario" } ] } ] }
}
EOF
printf '{"mcpServers":{"meu-servidor":{"type":"stdio","command":"meu-mcp"},"context7":{"type":"stdio","command":"custom-context7"}}}\n' > "$TARGET/.mcp.json"

echo "▶ Instalação (java + node), duas vezes"
bash "$CLAUDE_ROOT/scripts/install.sh" --skip-bun --stack java,node "$TARGET" > "$WORK/install1.log"
cp "$TARGET/.claude/settings.json" "$WORK/settings-1.json"
bash "$CLAUDE_ROOT/scripts/install.sh" --skip-bun --stack java,node "$TARGET" > "$WORK/install2.log"

check "AGENTS.md criado" "[ -f '$TARGET/AGENTS.md' ]"
check "CLAUDE.md do usuário preservado" "grep -q 'Instruções do time' '$TARGET/CLAUDE.md'"
check "CLAUDE.md importa @AGENTS.md uma única vez" "[ \"\$(grep -cx '@AGENTS.md' '$TARGET/CLAUDE.md')\" = 1 ]"
check "settings idêntico após reinstalar (idempotente)" "cmp -s '$WORK/settings-1.json' '$TARGET/.claude/settings.json'"
check "hook do usuário preservado" "grep -q 'echo usuario' '$TARGET/.claude/settings.json'"
check "allow do usuário preservado" "grep -q 'Bash(npm test)' '$TARGET/.claude/settings.json'"
check "deny sem duplicata" "[ \"\$(grep -c 'Edit(\*\*/.env)\"' '$TARGET/.claude/settings.json')\" = 1 ]"
check "hooks do kit registrados uma vez" "[ \"\$(grep -c 'rpe-guard-bash.ts' '$TARGET/.claude/settings.json')\" = 1 ]"
check "servidor MCP do usuário preservado" "[ \"\$(json '$TARGET/.mcp.json' 'd[\"mcpServers\"][\"context7\"][\"command\"]')\" = custom-context7 ]"
check "servidores do kit acrescentados" "[ \"\$(json '$TARGET/.mcp.json' 'len(d[\"mcpServers\"])')\" = 4 ]"
check ".gitignore com bloco único" "[ \"\$(grep -c 'RPE Harness (Claude Code)' '$TARGET/.gitignore')\" = 1 ]"
check "skill java instalada" "[ -f '$TARGET/.claude/skills/java-mastery/SKILL.md' ]"
check "skill react não instalada" "[ ! -e '$TARGET/.claude/skills/frontend-mastery' ]"
check "estado registra versão e stacks" "[ \"\$(json '$TARGET/.claude/harness-stacks.json' 'd[\"kitVersion\"] + \"|\" + \",\".join(d[\"stacks\"])')\" = \"$(tr -d '[:space:]' < "$CLAUDE_ROOT/VERSION")|java,node\" ]"

echo "▶ Validação no alvo"
if bash "$TARGET/.claude/rpe/validate.sh" > "$WORK/validate.log" 2>&1; then
  pass "validate.sh do alvo sem erros"
else
  fail "validate.sh do alvo falhou"
  cat "$WORK/validate.log"
fi

echo "▶ Update removendo a stack java"
bash "$CLAUDE_ROOT/scripts/update.sh" --no-pull --skip-bun --node "$TARGET" > "$WORK/update.log"
check "skills java removidas como órfãs" "[ ! -e '$TARGET/.claude/skills/java-mastery' ] && [ ! -e '$TARGET/.claude/skills/clean-architecture-ddd' ]"
check "rule java removida" "[ ! -e '$TARGET/.claude/rules/java-standards.md' ]"
check "skill universal mantida" "[ -f '$TARGET/.claude/skills/review-pr/SKILL.md' ]"
check "update relata as remoções" "grep -q 'removido (saiu do kit): .claude/skills/java-mastery/SKILL.md' '$WORK/update.log'"

echo "▶ Update sem flags reutiliza as stacks registradas"
bash "$CLAUDE_ROOT/scripts/update.sh" --no-pull --skip-bun "$TARGET" > "$WORK/update2.log"
check "stacks preservadas (node)" "grep -q 'Stacks registradas: node' '$WORK/update2.log'"

echo "▶ Arquivo do usuário em .claude/ fora do kit"
mkdir -p "$TARGET/.claude/agents"
printf -- '---\nname: meu-agente\ndescription: x\n---\nVer .cursor/rules/legado.mdc\n' > "$TARGET/.claude/agents/meu-agente.md"
check "validate ignora resíduo em arquivo do usuário" "bash '$TARGET/.claude/rpe/validate.sh' > /dev/null 2>&1"
check "update não remove arquivo do usuário" "bash '$CLAUDE_ROOT/scripts/update.sh' --no-pull --skip-bun '$TARGET' > /dev/null && [ -f '$TARGET/.claude/agents/meu-agente.md' ]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "install-smoke: OK"
else
  echo "install-smoke: $FAILURES falha(s)"
  exit 1
fi
