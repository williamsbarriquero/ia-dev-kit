#!/bin/bash
# RPE Harness (Claude Code) - manifesto de artefatos por stack.
# Compatível com bash 3.2 (macOS): sem arrays associativos nem mapfile.

ALL_STACKS=(java go node react)

# Rules sem stack: as globais (sem paths) e as contextuais universais.
HARNESS_CORE_RULES=(
  rpe-harness
  rpe-identity
  interaction-standards
  coding-standards
  intent-routing
  plan-to-specs
  project-baseline
  safety-guardrails
  stack-baseline
  testing-standards
  qa-standards
  database-migrations
  observability
)

STACK_RULES_java=(java-standards)
STACK_RULES_go=(go-standards)
STACK_RULES_node=(node-standards typescript)
STACK_RULES_react=(frontend-standards typescript)

STACK_SKILLS_java=(java-mastery clean-architecture java-test-layers clean-architecture-ddd)
STACK_SKILLS_go=(go-mastery)
STACK_SKILLS_node=(node-mastery)
STACK_SKILLS_react=(frontend-mastery)

STACK_KNOWLEDGE_java=(stacks/java.md)
STACK_KNOWLEDGE_go=(stacks/go.md)
STACK_KNOWLEDGE_node=(stacks/node.md)
STACK_KNOWLEDGE_react=(stacks/frontend.md)

# Skills de conhecimento, ex-rules sob demanda e workflows (ex-commands do Cursor).
UNIVERSAL_SKILLS=(
  accessibility-visual-testing
  api-contract-testing
  bdd-gherkin
  design-patterns
  e2e-testing
  hexagonal-architecture
  lsp-integration
  mcp-integration
  performance-testing
  pipeline-gateway
  session-persistence
  solid-principles
  tdd-grinder
  code-review
  git-conventions
  tdd-workflow
  audit-logs-otel
  audit-security
  generate-mocks
  generate-openapi
  generate-pr-description
  generate-test-cases
  plan-architecture
  refine-story
  review-migration
  review-pr
  scaffold-e2e
  scaffold-k6
  test-plan
  ultrawork
  validate-stack
)

is_valid_stack() {
  case "$1" in
    java|go|node|react) return 0 ;;
    *) return 1 ;;
  esac
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

add_stack_flag() {
  local stack
  stack="$(trim "$(echo "$1" | tr '[:upper:]' '[:lower:]')")"
  if ! is_valid_stack "$stack"; then
    echo "Stack inválida: $stack (use: java, go, node, react)" >&2
    return 1
  fi
  if [ "${#SELECTED_STACKS[@]}" -gt 0 ] && array_contains "$stack" "${SELECTED_STACKS[@]}"; then
    return 0
  fi
  SELECTED_STACKS+=("$stack")
}

expand_stack_list() {
  local part
  local parts=()
  IFS=',' read -ra parts <<< "$1"
  for part in "${parts[@]}"; do
    add_stack_flag "$part" || return 1
  done
}

resolve_stacks_from_flags() {
  SELECTED_STACKS=()
  STACK_MODE="all"

  if [ "$ALL_STACKS_FLAG" = true ]; then
    SELECTED_STACKS=("${ALL_STACKS[@]}")
    return 0
  fi

  if [ "$FLAG_JAVA" = true ]; then add_stack_flag java; fi
  if [ "$FLAG_GO" = true ]; then add_stack_flag go; fi
  if [ "$FLAG_NODE" = true ]; then add_stack_flag node; fi
  if [ "$FLAG_REACT" = true ]; then add_stack_flag react; fi
  if [ -n "$STACK_LIST" ]; then
    expand_stack_list "$STACK_LIST" || return 1
  fi

  if [ "${#SELECTED_STACKS[@]}" -eq 0 ]; then
    SELECTED_STACKS=("${ALL_STACKS[@]}")
    echo "ℹ️  Nenhuma stack informada: instalando todas (java, go, node, react)."
    echo "   Use --java, --go, --node, --react ou --stack java,react para instalação seletiva."
    return 0
  fi

  STACK_MODE="explicit"
}

stack_items() {
  # $1 = RULES|SKILLS|KNOWLEDGE, $2 = stack
  local var="STACK_${1}_${2}[@]"
  printf '%s\n' "${!var}"
}

append_unique() {
  # $1 = nome do array destino, demais = itens
  local target="$1"
  shift
  local item current
  for item in "$@"; do
    [ -z "$item" ] && continue
    eval "current=(\"\${${target}[@]}\")"
    if ! array_contains "$item" "${current[@]}"; then
      eval "${target}+=(\"\$item\")"
    fi
  done
}

resolve_install_sets() {
  INSTALL_RULES=("${HARNESS_CORE_RULES[@]}")
  INSTALL_SKILLS=("${UNIVERSAL_SKILLS[@]}")
  INSTALL_KNOWLEDGE=(README.md)
  local stack item
  for stack in "${SELECTED_STACKS[@]}"; do
    while IFS= read -r item; do append_unique INSTALL_RULES "$item"; done < <(stack_items RULES "$stack")
    while IFS= read -r item; do append_unique INSTALL_SKILLS "$item"; done < <(stack_items SKILLS "$stack")
    while IFS= read -r item; do append_unique INSTALL_KNOWLEDGE "$item"; done < <(stack_items KNOWLEDGE "$stack")
  done
}
