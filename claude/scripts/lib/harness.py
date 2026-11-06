#!/usr/bin/env python3
"""Operações JSON e validações do RPE Harness (Claude Code). Requer Python 3.9+.

Subcomandos:
  merge-settings <fragmento> <settings.json>   mescla hooks e permissions do kit
  merge-mcp <exemplo> <.mcp.json>              acrescenta servidores ausentes
  finalize <alvo> <lista-de-arquivos> ...      grava harness-stacks.json e remove órfãos
  read-stacks <harness-stacks.json>            imprime "modo" e "stacks,csv"
  lint <base> --mode kit|target                valida frontmatter, referências e resíduos
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

KIT_HOOK_MARKER = "/.claude/hooks/rpe-"
STATE_FILE = ".claude/harness-stacks.json"
MODEL_ALIASES = {"opus", "sonnet", "haiku", "fable", "inherit"}
KNOWN_TOOLS = {
    "Read", "Grep", "Glob", "Edit", "Write", "Bash", "LSP", "NotebookEdit", "WebFetch",
    "WebSearch", "Agent", "AskUserQuestion", "EnterPlanMode", "ExitPlanMode", "Skill",
}
RESIDUE = [
    (re.compile(r"\.cursor\b"), "caminho .cursor"),
    (re.compile(r"\.mdc\b"), "rule .mdc"),
    (re.compile(r"(?<![\w`])@[a-z][a-z0-9-]*\.md\b"), "invocação @x.md do Cursor"),
    (re.compile(r"SemanticSearch|CallMcpTool|TodoWrite"), "ferramenta do Cursor"),
    (re.compile(r"(?<![\w./-])agents\.md"), "agents.md minúsculo (use AGENTS.md)"),
]


def load_json(path, default):
    if not path.exists():
        return default
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def dump_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def is_kit_handler(handler):
    return KIT_HOOK_MARKER in str(handler.get("command", "")) + " ".join(map(str, handler.get("args", [])))


def merge_settings(fragment_path, settings_path):
    fragment = load_json(Path(fragment_path), {})
    settings = load_json(Path(settings_path), {})

    permissions = settings.setdefault("permissions", {})
    for key, rules in fragment.get("permissions", {}).items():
        current = permissions.setdefault(key, [])
        current.extend(rule for rule in rules if rule not in current)

    hooks = settings.setdefault("hooks", {})
    for event in list(hooks):
        groups = []
        for group in hooks[event]:
            kept = [h for h in group.get("hooks", []) if not is_kit_handler(h)]
            if kept:
                groups.append(dict(group, hooks=kept))
        if groups:
            hooks[event] = groups
        else:
            del hooks[event]
    for event, groups in fragment.get("hooks", {}).items():
        hooks.setdefault(event, []).extend(groups)

    dump_json(Path(settings_path), settings)
    print(f"   settings.json: {sum(len(g) for g in fragment.get('hooks', {}).values())} grupo(s) de hook do kit, permissions mescladas")


def merge_mcp(example_path, mcp_path):
    example = load_json(Path(example_path), {"mcpServers": {}})
    target_path = Path(mcp_path)
    existed = target_path.exists()
    current = load_json(target_path, {"mcpServers": {}})
    servers = current.setdefault("mcpServers", {})
    added = [name for name in example.get("mcpServers", {}) if name not in servers]
    for name in added:
        servers[name] = example["mcpServers"][name]
    dump_json(target_path, current)
    kept = len(servers) - len(added)
    state = "criado" if not existed else "mesclado"
    print(f"   .mcp.json {state}: {len(added)} servidor(es) adicionado(s), {kept} preservado(s)")


def finalize(target, files_list, kit_version, kit_path, mode, stacks, partial):
    root = Path(target).resolve()
    state_path = root / STATE_FILE
    previous = load_json(state_path, {})
    new_files = sorted({line.strip() for line in Path(files_list).read_text(encoding="utf-8").splitlines() if line.strip()})
    old_files = previous.get("files", [])

    removed = []
    if partial:
        new_files = sorted(set(new_files) | set(old_files))
    else:
        for rel in sorted(set(old_files) - set(new_files)):
            path = (root / rel).resolve()
            # Só remove o que o kit instalou dentro de .claude/.
            if (root / ".claude") in path.parents and path.is_file():
                path.unlink()
                removed.append(rel)
                parent = path.parent
                while parent != root / ".claude" and parent.is_dir() and not any(parent.iterdir()):
                    parent.rmdir()
                    parent = parent.parent

    dump_json(state_path, {
        "schema": 1,
        "kitVersion": kit_version,
        "kitPath": kit_path,
        "installedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "mode": mode,
        "stacks": [s for s in stacks.split(",") if s],
        "files": new_files,
    })
    for rel in removed:
        print(f"   removido (saiu do kit): {rel}")
    print(f"   Estado: {STATE_FILE} ({len(new_files)} arquivo(s) do kit)")


def read_stacks(state_file):
    data = load_json(Path(state_file), None)
    if data is None:
        return 1
    print(data.get("mode", "all"))
    print(",".join(data.get("stacks", [])))
    return 0


def frontmatter(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end < 0:
        return None
    fields, key = {}, None
    for line in text[4:end].splitlines():
        match = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if match:
            key = match.group(1)
            fields[key] = match.group(2).strip().strip('"').strip("'")
        elif key and line.strip().startswith("- "):
            fields[key] = (fields[key] + " " + line.strip()[2:]).strip()
    return fields


class Report:
    def __init__(self):
        self.errors, self.warnings = [], []

    def error(self, message):
        self.errors.append(message)

    def warn(self, message):
        self.warnings.append(message)


def owned_filter(base, mode, root):
    """No alvo, só os arquivos instalados pelo kit são validados; os do usuário ficam de fora."""
    if mode == "kit":
        return lambda path: True
    owned = set(load_json(root / STATE_FILE, {}).get("files", []))
    return lambda path: path.relative_to(root).as_posix() in owned


def lint_agents(base, report, owned):
    agents = sorted((base / "agents").glob("*.md"))
    for path in filter(owned, agents):
        fields = frontmatter(path.read_text(encoding="utf-8"))
        name = path.stem
        if fields is None:
            report.error(f"agents/{name}.md: sem frontmatter")
            continue
        if fields.get("name") != name:
            report.error(f"agents/{name}.md: name '{fields.get('name')}' difere do arquivo")
        if not fields.get("description"):
            report.error(f"agents/{name}.md: description vazia")
        model = fields.get("model", "inherit")
        if model not in MODEL_ALIASES and not model.startswith("claude-"):
            report.error(f"agents/{name}.md: model inválido '{model}'")
        for key in ("tools", "disallowedTools"):
            for tool in filter(None, (t.strip() for t in fields.get(key, "").split(","))):
                if tool not in KNOWN_TOOLS and not tool.startswith("mcp__"):
                    report.warn(f"agents/{name}.md: {key} com ferramenta desconhecida '{tool}'")
    return {p.stem for p in agents}


def lint_skills(base, report, agent_names, owned):
    skills = sorted(p for p in (base / "skills").iterdir() if p.is_dir()) if (base / "skills").is_dir() else []
    for skill_dir in skills:
        skill_file = skill_dir / "SKILL.md"
        if skill_file.exists() and not owned(skill_file):
            continue
        if not skill_file.exists():
            report.error(f"skills/{skill_dir.name}: sem SKILL.md")
            continue
        fields = frontmatter(skill_file.read_text(encoding="utf-8")) or {}
        if fields.get("name") != skill_dir.name:
            report.error(f"skills/{skill_dir.name}: name '{fields.get('name')}' difere da pasta")
        if not fields.get("description"):
            report.error(f"skills/{skill_dir.name}: description vazia")
        agent = fields.get("agent")
        if agent:
            if fields.get("context") != "fork":
                report.error(f"skills/{skill_dir.name}: 'agent' exige 'context: fork'")
            if agent not in agent_names:
                report.error(f"skills/{skill_dir.name}: agent '{agent}' não existe em agents/")
    return {p.name for p in skills}


def lint_rules(base, report, owned):
    rules = sorted((base / "rules").glob("*.md"))
    for path in filter(owned, rules):
        fields = frontmatter(path.read_text(encoding="utf-8"))
        if fields is not None and set(fields) - {"paths"}:
            report.error(f"rules/{path.name}: frontmatter só aceita 'paths' (achou {sorted(set(fields) - {'paths'})})")
    return {p.stem for p in rules}


def lint_text(base, report, mode, agent_names, skill_names, rule_names, owned):
    ref_level = report.error if mode == "kit" else report.warn
    for path in filter(owned, sorted(base.rglob("*.md"))):
        rel = path.relative_to(base)
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), 1):
            for pattern, label in RESIDUE:
                if pattern.search(line):
                    report.error(f"{rel}:{number}: resíduo Cursor ({label})")
        for agent in set(re.findall(r"subagent `(rpe-[a-z-]+)`", text)):
            if agent not in agent_names:
                report.error(f"{rel}: subagent `{agent}` inexistente")
        for skill in set(re.findall(r"\.claude/skills/([a-z0-9-]+)/", text)):
            if skill not in skill_names:
                ref_level(f"{rel}: skill '{skill}' referenciada e não instalada")
        for rule in set(re.findall(r"\.claude/rules/([a-z0-9-]+)\.md", text)):
            if rule not in rule_names:
                ref_level(f"{rel}: rule '{rule}' referenciada e não instalada")
        for knowledge in set(re.findall(r"\.claude/knowledge/(stacks/[a-z]+\.md)", text)):
            if not (base / "knowledge" / knowledge).exists():
                ref_level(f"{rel}: knowledge '{knowledge}' referenciado e não instalado")


def lint_settings(base, report, mode, root):
    hooks_dir = base / "hooks"
    if mode == "kit":
        settings = load_json(base / "settings.fragment.json", {})
    else:
        settings_path = root / ".claude" / "settings.json"
        if not settings_path.exists():
            report.error(".claude/settings.json ausente: hooks do kit não registrados")
            return
        settings = load_json(settings_path, {})
    commands = [
        h.get("command", "")
        for groups in settings.get("hooks", {}).values()
        for group in groups
        for h in group.get("hooks", [])
        if is_kit_handler(h)
    ]
    if not commands:
        report.error("nenhum hook do kit registrado no settings")
    for command in commands:
        script = re.search(r"\.claude/hooks/(rpe-[a-z-]+\.ts)", command)
        if script and not (hooks_dir / script.group(1)).exists():
            report.error(f"hook registrado sem script: {script.group(1)}")


def lint(base_arg, mode):
    base = Path(base_arg).resolve()
    root = base.parent if mode == "target" else base
    report = Report()
    owned = owned_filter(base, mode, root)
    agent_names = lint_agents(base, report, owned)
    skill_names = lint_skills(base, report, agent_names, owned)
    rule_names = lint_rules(base, report, owned)
    lint_text(base, report, mode, agent_names, skill_names, rule_names, owned)
    lint_settings(base, report, mode, root)
    for path in ([base / "mcp.json.example"] if mode == "kit" else [root / ".mcp.json", root / STATE_FILE]):
        if path.exists():
            try:
                load_json(path, None)
            except json.JSONDecodeError as exc:
                report.error(f"{path.name}: JSON inválido ({exc})")
    for warning in report.warnings:
        print(f"WARN  {warning}")
    for error in report.errors:
        print(f"ERROR {error}")
    print(f"INFO  {len(agent_names)} agents, {len(skill_names)} skills, {len(rule_names)} rules")
    return 1 if report.errors else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("merge-settings"); p.add_argument("fragment"); p.add_argument("settings")
    p = sub.add_parser("merge-mcp"); p.add_argument("example"); p.add_argument("mcp")
    p = sub.add_parser("finalize")
    p.add_argument("target"); p.add_argument("files_list")
    p.add_argument("--kit-version", required=True); p.add_argument("--kit-path", required=True)
    p.add_argument("--mode", required=True); p.add_argument("--stacks", required=True)
    p.add_argument("--partial", action="store_true")
    p = sub.add_parser("read-stacks"); p.add_argument("state_file")
    p = sub.add_parser("lint"); p.add_argument("base"); p.add_argument("--mode", choices=["kit", "target"], required=True)
    args = parser.parse_args()

    if args.command == "merge-settings":
        merge_settings(args.fragment, args.settings)
    elif args.command == "merge-mcp":
        merge_mcp(args.example, args.mcp)
    elif args.command == "finalize":
        finalize(args.target, args.files_list, args.kit_version, args.kit_path, args.mode, args.stacks, args.partial)
    elif args.command == "read-stacks":
        return read_stacks(args.state_file)
    elif args.command == "lint":
        return lint(args.base, args.mode)
    return 0


if __name__ == "__main__":
    sys.exit(main())
