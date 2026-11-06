#!/usr/bin/env python3
"""Conversão única do kit Cursor (.cursor/) para o payload Claude Code (claude/kit/).

Não é sincronização. Gera a base mecânica (frontmatter, caminhos, invocações,
nomes de ferramentas); os arquivos com semântica própria do Cursor são
reescritos à mão depois, e a árvore claude/kit/ evolui sozinha a partir daí.

Uso:
    python3 claude/tools/migrate-from-cursor.py            # recusa se claude/kit/ já existir
    python3 claude/tools/migrate-from-cursor.py --force    # sobrescreve os arquivos gerados
"""
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / ".cursor"
DST = ROOT / "claude" / "kit"

ALWAYS_RULES = [
    "coding-standards",
    "intent-routing",
    "interaction-standards",
    "plan-to-specs",
    "project-baseline",
    "rpe-identity",
    "safety-guardrails",
    "stack-baseline",
]

GLOB_RULES = [
    "database-migrations",
    "frontend-standards",
    "go-standards",
    "java-standards",
    "node-standards",
    "observability",
    "qa-standards",
    "testing-standards",
    "typescript",
]

# Rules "agent-requestable" do Cursor: viram skills que o modelo escolhe pela description.
RULES_TO_SKILLS = {
    "code-review": (
        "Checklist e formato de relatório de code review RPE (segurança, performance, "
        "legibilidade, testes, arquitetura). Use ao revisar PR, diff ou código."
    ),
    "git-conventions": (
        "Convenções Git RPE: Conventional Commits, nomes de branch, commits atômicos e "
        "template de PR. Use ao criar commits, branches ou PRs."
    ),
    "tdd-workflow": (
        "Fluxo TDD RPE (RED, GREEN, REFACTOR) com subagents e scratchpad. Use ao "
        "implementar com testes primeiro ou quando o pedido citar TDD."
    ),
}

# A rule ultrawork é fundida à mão na skill /ultrawork.
SKIPPED_RULES = {"ultrawork"}
CONVERTED_RULE_NAMES = "code-review|git-conventions|tdd-workflow|ultrawork"

OPUS, SONNET = "opus", "sonnet"

AGENTS = {
    "rpe-architect": {
        "model": OPUS,
        "tools": "Read, Grep, Glob, Edit, Write, AskUserQuestion, EnterPlanMode, ExitPlanMode",
        "description": (
            "Arquiteto de sistemas RPE. Desenha a spec da feature (contexto, capacidades, "
            "componentes, interações, contratos) e, após a aprovação, grava "
            "docs/specs/<slug>/feature.md e technical.md. Use para desenho de feature, "
            "novo módulo ou preenchimento do baseline AGENTS.md. Não escreve código."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`, `AskUserQuestion` e Plan Mode.\n"
            "- **Escrita**: só `AGENTS.md` na raiz (preencher placeholder) e `docs/specs/<slug>/` "
            "(depois da aprovação). O hook `rpe-guard-write.ts` bloqueia qualquer outro caminho.\n"
            "- **Sem**: `Bash`, delegação a outros subagents."
        ),
    },
    "rpe-developer": {
        "model": OPUS,
        "tools": "Read, Grep, Glob, Edit, Write, Bash, LSP",
        "disallowed": "Agent",
        "description": (
            "Desenvolvedor RPE. Implementa código de produção a partir da spec "
            "(docs/specs/<slug>/technical.md): GREEN e REFACTOR do ciclo TDD, ou "
            "implementação direta quando o pedido for sem TDD."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash`, `LSP` (se houver plugin de code intelligence).\n"
            "- **Sem**: delegação a outros subagents (evita loops)."
        ),
    },
    "rpe-reviewer": {
        "model": OPUS,
        "tools": "Read, Grep, Glob, Bash",
        "description": (
            "Revisor de código RPE. Revisa diff, branch ou PR contra arquitetura, "
            "segurança e qualidade, e gera descrição de PR. Somente leitura."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob` e `Bash` somente leitura "
            "(`git diff`, `git log`, `git show`). O hook `rpe-guard-bash.ts` bloqueia comandos que alteram estado.\n"
            "- **Sem**: `Edit`, `Write`, delegação a outros subagents."
        ),
    },
    "rpe-test-lead": {
        "model": OPUS,
        "tools": "Read, Grep, Glob",
        "description": (
            "Líder de testes RPE. Deriva o plano técnico TDD (P0 a P3, ordem, mocks) a "
            "partir da spec aprovada. Não escreve código de teste. Somente leitura."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`.\n"
            "- **Sem**: `Edit`, `Write`, `Bash`, delegação a outros subagents."
        ),
    },
    "rpe-tester": {
        "model": OPUS,
        "tools": "Read, Grep, Glob, Edit, Write, Bash, LSP",
        "disallowed": "Agent",
        "description": (
            "Executor de testes RPE. Escreve e roda testes unitários e de integração: RED "
            "do ciclo TDD (testes que falham) ou testes pós-implementação. Atualiza o scratchpad."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash`, `LSP` (se houver plugin de code intelligence).\n"
            "- **Sem**: delegação a outros subagents."
        ),
    },
    "rpe-security": {
        "model": SONNET,
        "tools": "Read, Grep, Glob, Bash",
        "description": (
            "Especialista DevSecOps e AppSec RPE: OWASP, supply chain, SLSA, IaC, K8s, "
            "segredos e PII em logs. Use para auditoria de segurança profunda. Somente leitura."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob` e `Bash` só para auditoria "
            "(`npm audit`, scanners, `git diff`). O hook `rpe-guard-bash.ts` bloqueia comandos que alteram estado.\n"
            "- **Sem**: `Edit`, `Write`, delegação a outros subagents."
        ),
    },
    "rpe-qa-analyst": {
        "model": SONNET,
        "tools": "Read, Grep, Glob",
        "description": (
            "Analista de QA RPE. Estratégia de validação funcional, cenários BDD/Gherkin, "
            "valor limite, acessibilidade e refinamento de histórias. Somente leitura."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`.\n"
            "- **Sem**: `Edit`, `Write`, `Bash`, delegação a outros subagents."
        ),
    },
    "rpe-sdet": {
        "model": SONNET,
        "tools": "Read, Grep, Glob, Edit, Write, Bash",
        "disallowed": "Agent",
        "description": (
            "SDET RPE. Automação E2E (Playwright, Cypress), testes de API e contrato, mocks "
            "(MSW, WireMock), k6 e integração da suíte no CI."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash`.\n"
            "- **Sem**: delegação a outros subagents."
        ),
    },
    "rpe-tech-writer": {
        "model": SONNET,
        "tools": "Read, Grep, Glob, Edit, Write",
        "description": (
            "Tech writer RPE. README, CONTRIBUTING, CHANGELOG, ARCHITECTURE, OpenAPI e "
            "diagramas Mermaid sincronizados com o código."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`.\n"
            "- **Sem**: `Bash`, delegação a outros subagents."
        ),
    },
    "rpe-atlassian": {
        "model": SONNET,
        "disallowed": "Edit, Write, NotebookEdit, Bash, Agent",
        "description": (
            "Especialista Atlassian RPE. Traduz specs em épicos, histórias e tasks no Jira e "
            "publica RFCs e design docs no Confluence via MCP. Somente leitura no repositório."
        ),
        "tools_section": (
            "- **Ferramentas**: leitura do repositório e as tools do servidor MCP `atlassian` "
            "(`mcp__atlassian__*`), quando configurado em `.mcp.json`.\n"
            "- **Sem**: `Edit`, `Write`, `Bash`, delegação a outros subagents."
        ),
    },
    "rpe-infra": {
        "model": SONNET,
        "tools": "Read, Grep, Glob, Edit, Write, Bash",
        "disallowed": "Agent",
        "description": (
            "Especialista em infraestrutura RPE: CI/CD (GitHub Actions, GitLab CI), Docker, "
            "Kubernetes, Terraform e falhas de build ou deploy."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash`.\n"
            "- **Sem**: delegação a outros subagents."
        ),
    },
    "rpe-dba": {
        "model": SONNET,
        "tools": "Read, Grep, Glob, Edit, Write, Bash",
        "disallowed": "Agent",
        "description": (
            "DBA RPE. Migrações seguras com rollback, expand-and-contract, índices em FKs, "
            "modelagem e revisão de queries."
        ),
        "tools_section": (
            "- **Ferramentas**: `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash`.\n"
            "- **Sem**: delegação a outros subagents."
        ),
    },
}

# Commands viram skills /<nome>. Os que pertencem a um agent rodam nele (context: fork).
COMMANDS = {
    "audit-logs-otel": ("Audita logs e spans: PII/LGPD, propagação de trace context e níveis de severidade.", "rpe-security", "[arquivos ou escopo]"),
    "audit-security": ("Varredura de segurança (OWASP Top 10, segredos, dependências) no diff ou no escopo indicado.", "rpe-security", "[arquivos, diretório ou branch]"),
    "generate-mocks": ("Gera mocks de API (MSW, WireMock, mocks Go) a partir de OpenAPI, Swagger ou payload JSON.", "rpe-sdet", "[schema ou payload]"),
    "generate-openapi": ("Gera ou atualiza a especificação OpenAPI 3.x das rotas indicadas.", "rpe-tech-writer", "[rotas ou controllers]"),
    "generate-pr-description": ("Gera a descrição padronizada de PR a partir do diff da branch.", "rpe-reviewer", "[branch de destino]"),
    "generate-test-cases": ("Gera cenários BDD/Gherkin, casos de valor limite e checklist não funcional.", "rpe-qa-analyst", "[arquivo ou funcionalidade]"),
    "plan-architecture": ("Desenha a spec da feature e, após a aprovação, grava docs/specs/<slug>/feature.md e technical.md.", None, "[descrição da feature]"),
    "refine-story": ("Refinamento Três Amigos de história ou ticket: checklist de engenharia e de QA.", "rpe-qa-analyst", "[história ou ticket]"),
    "review-migration": ("Revisa migração de banco contra o checklist RPE (rollback, expand-and-contract, índices, locks).", "rpe-dba", "[arquivo de migração]"),
    "review-pr": ("Revisa o PR ou a branch atual contra o checklist RPE e gera relatório para colar no PR.", "rpe-reviewer", "[branch de destino]"),
    "scaffold-e2e": ("Cria a estrutura de testes E2E (Playwright ou Cypress) com Page Object Model para o fluxo indicado.", "rpe-sdet", "[fluxo]"),
    "scaffold-k6": ("Cria script de performance k6 (load, stress, spike ou soak) para o endpoint ou fluxo indicado.", "rpe-sdet", "[endpoint ou fluxo]"),
    "test-plan": ("Gera o plano técnico TDD (P0 a P3, ordem, mocks) a partir da spec aprovada.", "rpe-test-lead", "[slug da spec]"),
    "ultrawork": ("Modo UltraWork: ciclo TDD autônomo com auto-correção até a suíte passar (até 5 iterações).", None, "[slug da spec ou objetivo]"),
    "validate-stack": ("Roda lint, format, type-check e testes da stack e reporta exit codes (Definition of Done).", None, None),
}

SUBSTITUTIONS = [
    # Caminhos completos primeiro.
    (r"`@\.cursor/docs/specs/", "`docs/specs/"),
    (r"\.cursor/hooks/continuations/grind-loop\.ts", ".claude/hooks/rpe-grind-loop.ts"),
    (r"\.cursor/hooks\.json", ".claude/settings.json"),
    (r"\.cursor/mcp\.json(?:\.example)?", ".mcp.json"),
    (r"\.cursor/docs/specs/", "docs/specs/"),
    (r"\.cursor/scratchpad", ".claude/scratchpad"),
    (r"\.cursor/(knowledge|skills|templates|harness-stacks\.json)", r".claude/\1"),
    (r"\.cursor/rules/(" + CONVERTED_RULE_NAMES + r")\.mdc", r".claude/skills/\1/SKILL.md"),
    (r"\.cursor/rules/([a-z0-9-]+)\.mdc", r".claude/rules/\1.md"),
    (r"\.cursor/commands/([a-z0-9-]+)\.md", r".claude/skills/\1/SKILL.md"),
    # Nomes de rule soltos.
    (r"`(" + CONVERTED_RULE_NAMES + r")\.mdc`", r"skill `\1`"),
    (r"`([a-z0-9<>-]+)\.mdc`", r"rule `\1`"),
    # Invocações @x.md: agents viram subagents, commands viram skills /x.
    (r"`@(rpe-[a-z-]+)\.md`", r"subagent `\1`"),
    (r"@(rpe-[a-z-]+)\.md", r"subagent `\1`"),
    (r"`@([a-z0-9-]+)\.md`", r"`/\1`"),
    (r"(?<![\w`])@([a-z][a-z0-9-]*)\.md\b", r"`/\1`"),
    # MCP e baseline.
    (r"\$\{env:([A-Z0-9_]+)\}", r"${\1}"),
    (r"(?<![\w./-])agents\.md", "AGENTS.md"),
    (r"(?<!rpe-)grind-loop\.ts", "rpe-grind-loop.ts"),
    # Frases de UX do Cursor (anexar arquivo, chamar um agente por chat).
    # A frase termina no primeiro ponto fora de crases (`AGENTS.md` não encerra a frase).
    (r" ?O usuário (?:não anexa|chama só)(?:[^.`]|`[^`]*`)*\.", ""),
    (r"[Rr]egra rule `", "rule `"),
    (r"/agents\.md\)", "/AGENTS.md)"),
    # Skills com disable-model-invocation não carregam pela tool Skill: a ponte usa o caminho.
    (r"leia (a skill )?\*\*`([a-z-]+-mastery)`\*\*", r"leia \1**`\2`** (`.claude/skills/\2/SKILL.md`)"),
]

RESIDUE = re.compile(
    r"\.cursor|\.mdc\b|@[a-z][a-z0-9-]*\.md|SemanticSearch|CallMcpTool|TodoWrite|\bCursor\b|\bagents\.md"
)


def transform(text):
    for pattern, repl in SUBSTITUTIONS:
        text = re.sub(pattern, repl, text)
    return text


def split_frontmatter(text):
    if not text.startswith("---\n"):
        return {}, [], text
    end = text.index("\n---", 4)
    raw = text[4:end].splitlines()
    body = text[end + 4:].lstrip("\n")
    fields = {}
    for line in raw:
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if m:
            fields[m.group(1)] = m.group(2).strip()
    return fields, raw, body


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def yaml_str(value):
    return json.dumps(value, ensure_ascii=False)


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip("\n") + "\n", encoding="utf-8")


def convert_rules():
    for name in ALWAYS_RULES:
        _, _, body = split_frontmatter((SRC / "rules" / f"{name}.mdc").read_text(encoding="utf-8"))
        write(DST / "rules" / f"{name}.md", transform(body))

    for name in GLOB_RULES:
        fields, _, body = split_frontmatter((SRC / "rules" / f"{name}.mdc").read_text(encoding="utf-8"))
        globs = json.loads(fields["globs"])
        paths = "\n".join(f"  - {yaml_str(g)}" for g in globs)
        write(DST / "rules" / f"{name}.md", f"---\npaths:\n{paths}\n---\n\n{transform(body)}")

    for name, description in RULES_TO_SKILLS.items():
        _, _, body = split_frontmatter((SRC / "rules" / f"{name}.mdc").read_text(encoding="utf-8"))
        front = f"---\nname: {name}\ndescription: {yaml_str(description)}\n---\n\n"
        write(DST / "skills" / name / "SKILL.md", front + transform(body))


def replace_tools_section(body, section):
    pattern = re.compile(r"## Ferramentas\n.*?(?=\n## )", re.S)
    if not pattern.search(body):
        raise SystemExit("seção ## Ferramentas não encontrada")
    return pattern.sub(lambda _: f"## Ferramentas\n\n{section}\n", body, count=1)


def convert_agents():
    for name, spec in AGENTS.items():
        _, _, body = split_frontmatter((SRC / "agents" / f"{name}.md").read_text(encoding="utf-8"))
        lines = [
            "---",
            f"name: {name}",
            f"description: {yaml_str(spec['description'])}",
            f"model: {spec['model']}",
        ]
        if spec.get("tools"):
            lines.append(f"tools: {spec['tools']}")
        if spec.get("disallowed"):
            lines.append(f"disallowedTools: {spec['disallowed']}")
        lines.append("---")
        body = replace_tools_section(body, spec["tools_section"])
        write(DST / "agents" / f"{name}.md", "\n".join(lines) + "\n\n" + transform(body))


def convert_commands():
    for name, (description, agent, hint) in COMMANDS.items():
        body = (SRC / "commands" / f"{name}.md").read_text(encoding="utf-8")
        lines = ["---", f"name: {name}", f"description: {yaml_str(description)}"]
        if hint:
            lines.append(f"argument-hint: {yaml_str(hint)}")
        lines.append("disable-model-invocation: true")
        if agent:
            lines += ["context: fork", f"agent: {agent}"]
        lines.append("---")
        write(DST / "skills" / name / "SKILL.md", "\n".join(lines) + "\n\n" + transform(body))


def convert_skills():
    for skill_dir in sorted((SRC / "skills").iterdir()):
        if not skill_dir.is_dir():
            continue
        for src in sorted(skill_dir.rglob("*.md")):
            rel = src.relative_to(SRC / "skills")
            write(DST / "skills" / rel, transform(src.read_text(encoding="utf-8")))


def convert_plain_files():
    for src in sorted((SRC / "knowledge").rglob("*.md")):
        write(DST / "knowledge" / src.relative_to(SRC / "knowledge"), transform(src.read_text(encoding="utf-8")))
    for name in ("feature-spec.md", "technical-spec.md", "definition-of-done.md"):
        write(DST / "templates" / name, transform((ROOT / "templates" / name).read_text(encoding="utf-8")))
    write(DST / "scratchpad.template.md", transform((SRC / "scratchpad.template.md").read_text(encoding="utf-8")))
    write(DST / "specs" / "README.md", transform((SRC / "docs" / "specs" / "README.md").read_text(encoding="utf-8")))


def report_residue():
    hits = []
    for path in sorted(DST.rglob("*.md")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if RESIDUE.search(line):
                hits.append(f"{path.relative_to(ROOT)}:{number}: {line.strip()[:140]}")
    print(f"\nResíduos Cursor para revisão manual: {len(hits)}")
    for hit in hits:
        print("  " + hit)


def main():
    force = "--force" in sys.argv[1:]
    if DST.exists() and not force:
        raise SystemExit(f"{DST} já existe. Use --force para regenerar (sobrescreve edições manuais).")
    for sub in ("rules", "agents", "skills", "knowledge", "templates", "specs"):
        shutil.rmtree(DST / sub, ignore_errors=True)
    convert_rules()
    convert_agents()
    convert_commands()
    convert_skills()
    convert_plain_files()
    counts = {sub: len(list((DST / sub).glob("*"))) for sub in ("rules", "agents", "skills")}
    print(f"Gerado em {DST.relative_to(ROOT)}: {counts}")
    report_residue()


if __name__ == "__main__":
    main()
