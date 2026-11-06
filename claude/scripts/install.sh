#!/bin/bash
# RPE Harness para Claude Code - instalador.
# Copia o payload de claude/kit/ para <alvo>/.claude/ e mescla settings.json e .mcp.json.
set -euo pipefail

SKIP_BUN=false
ALL_STACKS_FLAG=false
FLAG_JAVA=false
FLAG_GO=false
FLAG_NODE=false
FLAG_REACT=false
STACK_LIST=""
TARGET_DIR=""
MODULES="all"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(dirname "$SCRIPT_DIR")"
KIT_DIR="$CLAUDE_ROOT/kit"
HARNESS_PY="$SCRIPT_DIR/lib/harness.py"
KIT_VERSION="$(tr -d '[:space:]' < "$CLAUDE_ROOT/VERSION")"
ALL_MODULES=(rules agents skills knowledge hooks settings mcp templates baseline validate)

# shellcheck source=lib/stack-manifest.sh
source "$SCRIPT_DIR/lib/stack-manifest.sh"

usage() {
  cat <<EOF
Uso: $0 [opções] <projeto-alvo> [módulos]

RPE Harness para Claude Code v$KIT_VERSION.

Stacks (combináveis; sem flag instala todas):
  --java        java-standards, java-mastery, clean-architecture, java-test-layers, clean-architecture-ddd
  --go          go-standards, go-mastery
  --node        node-standards, typescript, node-mastery
  --react       frontend-standards, typescript, frontend-mastery
  --stack LIST  atalho: --stack java,react
  --all-stacks  todas as stacks

Outras opções:
  --skip-bun    não instala o Bun (os hooks do kit precisam dele)

Módulos (CSV; padrão: todos): ${ALL_MODULES[*]}

Exemplos:
  $0 --java ~/projetos/api
  $0 --stack node,react ~/projetos/web
  $0 --node ~/projetos/api hooks,settings
EOF
  exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-bun) SKIP_BUN=true; shift ;;
    --all-stacks) ALL_STACKS_FLAG=true; shift ;;
    --java) FLAG_JAVA=true; shift ;;
    --go) FLAG_GO=true; shift ;;
    --node) FLAG_NODE=true; shift ;;
    --react) FLAG_REACT=true; shift ;;
    --stack)
      [ -z "${2:-}" ] && { echo "Erro: --stack requer uma lista (ex: java,react)" >&2; usage; }
      STACK_LIST="$2"
      shift 2
      ;;
    -h|--help) usage 0 ;;
    -*) echo "Opção desconhecida: $1" >&2; usage ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
      elif [ "$MODULES" = "all" ]; then
        MODULES="$1"
      else
        echo "Argumento inesperado: $1" >&2
        usage
      fi
      shift
      ;;
  esac
done

[ -z "$TARGET_DIR" ] && usage
[ -d "$TARGET_DIR" ] || { echo "Erro: diretório alvo não existe: $TARGET_DIR" >&2; exit 1; }
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
command -v python3 >/dev/null 2>&1 || { echo "Erro: python3 é necessário para mesclar settings.json e .mcp.json." >&2; exit 1; }

PARTIAL=false
if [ "$MODULES" = "all" ]; then
  MODULE_LIST=("${ALL_MODULES[@]}")
else
  PARTIAL=true
  IFS=',' read -ra MODULE_LIST <<< "$MODULES"
  for mod in "${MODULE_LIST[@]}"; do
    array_contains "$(trim "$mod")" "${ALL_MODULES[@]}" || { echo "Módulo desconhecido: $mod" >&2; usage; }
  done
fi

resolve_stacks_from_flags
resolve_install_sets

FILES_LIST="$(mktemp)"
trap 'rm -f "$FILES_LIST"' EXIT

copy_file() {
  # $1 = origem, $2 = destino relativo ao alvo (registrado como arquivo do kit)
  local dest="$TARGET_DIR/$2"
  mkdir -p "$(dirname "$dest")"
  cp "$1" "$dest"
  echo "$2" >> "$FILES_LIST"
}

copy_tree() {
  local src="$1" rel="$2" file
  while IFS= read -r file; do
    copy_file "$file" "$rel/${file#"$src"/}"
  done < <(find "$src" -type f ! -name '.DS_Store' | sort)
}

install_rules() {
  local rule
  for rule in "${INSTALL_RULES[@]}"; do
    copy_file "$KIT_DIR/rules/$rule.md" ".claude/rules/$rule.md"
  done
  echo "   Rules: ${#INSTALL_RULES[@]}"
}

install_agents() {
  local file count=0
  for file in "$KIT_DIR"/agents/*.md; do
    copy_file "$file" ".claude/agents/$(basename "$file")"
    count=$((count + 1))
  done
  echo "   Subagents: $count"
}

install_skills() {
  local skill
  for skill in "${INSTALL_SKILLS[@]}"; do
    copy_tree "$KIT_DIR/skills/$skill" ".claude/skills/$skill"
  done
  echo "   Skills: ${#INSTALL_SKILLS[@]}"
}

install_knowledge() {
  local file
  for file in "${INSTALL_KNOWLEDGE[@]}"; do
    copy_file "$KIT_DIR/knowledge/$file" ".claude/knowledge/$file"
  done
  echo "   Knowledge: ${#INSTALL_KNOWLEDGE[@]}"
}

install_hooks() {
  copy_tree "$KIT_DIR/hooks" ".claude/hooks"
  echo "   Hooks: .claude/hooks/rpe-*.ts"
}

install_templates() {
  copy_tree "$KIT_DIR/templates" ".claude/templates"
  copy_file "$KIT_DIR/scratchpad.template.md" ".claude/scratchpad.template.md"
  if [ ! -f "$TARGET_DIR/docs/specs/README.md" ]; then
    mkdir -p "$TARGET_DIR/docs/specs"
    cp "$KIT_DIR/specs/README.md" "$TARGET_DIR/docs/specs/README.md"
    echo "   docs/specs/README.md criado"
  fi
  echo "   Templates: .claude/templates/ e scratchpad.template.md"
}

ensure_gitignore() {
  local file="$TARGET_DIR/.gitignore" marker="# RPE Harness (Claude Code)"
  if grep -qF "$marker" "$file" 2>/dev/null; then
    return 0
  fi
  {
    [ -s "$file" ] && echo ""
    echo "$marker"
    echo ".rpe/"
    echo ".claude/settings.local.json"
    echo "CLAUDE.local.md"
  } >> "$file"
  echo "   .gitignore: entradas do harness adicionadas"
}

install_baseline() {
  # AGENTS.md e CLAUDE.md são do projeto: nunca sobrescritos.
  local baseline="AGENTS.md"
  if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    echo "   AGENTS.md já existe: preservado"
  elif [ -f "$TARGET_DIR/agents.md" ]; then
    baseline="agents.md"
    echo "   ⚠️  agents.md (minúsculo) encontrado e preservado; renomeie para AGENTS.md quando puder"
  else
    cp "$KIT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    echo "   AGENTS.md criado (placeholders _[PREENCHER]_ para o primeiro agente)"
  fi

  if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
    sed "s/^@AGENTS\.md$/@$baseline/" "$KIT_DIR/CLAUDE.md" > "$TARGET_DIR/CLAUDE.md"
    echo "   CLAUDE.md criado com @$baseline"
  elif grep -qx "@$baseline" "$TARGET_DIR/CLAUDE.md"; then
    echo "   CLAUDE.md já importa @$baseline: preservado"
  else
    printf '\n@%s\n' "$baseline" >> "$TARGET_DIR/CLAUDE.md"
    echo "   CLAUDE.md existente: import @$baseline acrescentado"
  fi
  ensure_gitignore
}

install_validate() {
  copy_file "$SCRIPT_DIR/validate.sh" ".claude/rpe/validate.sh"
  copy_file "$SCRIPT_DIR/lib/harness.py" ".claude/rpe/lib/harness.py"
  copy_file "$SCRIPT_DIR/lib/stack-manifest.sh" ".claude/rpe/lib/stack-manifest.sh"
  chmod +x "$TARGET_DIR/.claude/rpe/validate.sh"
  echo "   Validação: .claude/rpe/validate.sh"
}

ensure_bun() {
  if command -v bun >/dev/null 2>&1; then
    echo "✅ Bun disponível: $(bun --version)"
    return 0
  fi
  echo "📦 Instalando Bun (os hooks do kit rodam com bun)..."
  command -v curl >/dev/null 2>&1 || { echo "⚠️  curl ausente: instale o Bun manualmente (https://bun.sh)"; return 1; }
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  export PATH="$BUN_INSTALL/bin:$PATH"
  command -v bun >/dev/null 2>&1 && { echo "✅ Bun instalado: $(bun --version)"; return 0; }
  echo "⚠️  Bun instalado em $BUN_INSTALL/bin, mas fora do PATH desta sessão."
  return 1
}

echo "🚀 RPE Harness para Claude Code v$KIT_VERSION → $TARGET_DIR"
echo "📦 Stacks: ${SELECTED_STACKS[*]} (modo: $STACK_MODE) | módulos: ${MODULE_LIST[*]}"

HOOKS_SELECTED=false
for mod in "${MODULE_LIST[@]}"; do
  mod="$(trim "$mod")"
  case "$mod" in
    rules) install_rules ;;
    agents) install_agents ;;
    skills) install_skills ;;
    knowledge) install_knowledge ;;
    hooks) install_hooks; HOOKS_SELECTED=true ;;
    settings) python3 "$HARNESS_PY" merge-settings "$KIT_DIR/settings.fragment.json" "$TARGET_DIR/.claude/settings.json" ;;
    mcp) python3 "$HARNESS_PY" merge-mcp "$KIT_DIR/mcp.json.example" "$TARGET_DIR/.mcp.json" ;;
    templates) install_templates ;;
    baseline) install_baseline ;;
    validate) install_validate ;;
  esac
done

FINALIZE_ARGS=(
  --kit-version "$KIT_VERSION"
  --kit-path "$CLAUDE_ROOT"
  --mode "$STACK_MODE"
  --stacks "$(IFS=,; echo "${SELECTED_STACKS[*]}")"
)
[ "$PARTIAL" = true ] && FINALIZE_ARGS+=(--partial)
python3 "$HARNESS_PY" finalize "$TARGET_DIR" "$FILES_LIST" "${FINALIZE_ARGS[@]}"

if [ "$HOOKS_SELECTED" = true ]; then
  if [ "$SKIP_BUN" = true ]; then
    command -v bun >/dev/null 2>&1 || echo "⚠️  --skip-bun sem Bun no PATH: os hooks do kit não vão rodar (guards ficam inativos)."
  else
    ensure_bun || echo "⚠️  Sem Bun os hooks do kit não rodam. Instale: https://bun.sh"
  fi
fi

cat <<EOF
✅ Harness instalado.

Próximos passos:
  1. Abra o projeto com 'claude'. Aceite a confiança no workspace (habilita os hooks) e aprove os servidores do .mcp.json.
  2. Peça para preencher o baseline do AGENTS.md, ou comece por /plan-architecture <feature>.
  3. Valide: bash .claude/rpe/validate.sh
  4. Opcional: plugin de code intelligence para a tool LSP (ex.: /plugin install typescript-lsp@claude-plugins-official).
EOF
