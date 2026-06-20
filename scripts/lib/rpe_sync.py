#!/usr/bin/env python3
"""RPE Harness multi-IDE sync engine."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any


def kit_root() -> Path:
    return Path(__file__).resolve().parent.parent.parent


def parse_frontmatter(content: str) -> tuple[dict[str, str], str]:
    """Parse simple YAML frontmatter (key: value, lists, quoted strings)."""
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    meta: dict[str, str] = {}
    for line in parts[1].strip().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1]
            items = [i.strip().strip('"').strip("'") for i in inner.split(",") if i.strip()]
            meta[key] = items  # type: ignore[assignment]
        elif value.startswith('"') and value.endswith('"'):
            meta[key] = value[1:-1]
        elif value.startswith("'") and value.endswith("'"):
            meta[key] = value[1:-1]
        else:
            meta[key] = value

    body = parts[2].lstrip("\n")
    return meta, body  # type: ignore[return-value]


def format_frontmatter(meta: dict[str, Any]) -> str:
    lines = ["---"]
    for key, value in meta.items():
        if isinstance(value, list):
            formatted = ", ".join(f'"{v}"' for v in value)
            lines.append(f"{key}: [{formatted}]")
        elif isinstance(value, bool):
            lines.append(f"{key}: {'true' if value else 'false'}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def read_mdc(path: Path) -> tuple[dict[str, Any], str]:
    content = path.read_text(encoding="utf-8")
    return parse_frontmatter(content)  # type: ignore[return-value]


def globs_to_apply_to(globs: Any) -> str:
    if isinstance(globs, list):
        return ",".join(globs)
    if isinstance(globs, str):
        return globs.replace('"', "").replace("'", "")
    return "**"


def globs_to_paths(globs: Any) -> list[str]:
    if isinstance(globs, list):
        return globs
    if isinstance(globs, str):
        return [g.strip().strip('"').strip("'") for g in globs.split(",")]
    return ["**"]


def write_file(path: Path, content: str, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def copy_tree(src: Path, dst: Path, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] copy {src} -> {dst}")
        return
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def sync_cursor(root: Path, target: Path, dry_run: bool) -> None:
    cursor_src = root / ".cursor"
    cursor_dst = target / ".cursor"
    if dry_run:
        print(f"[dry-run] copy {cursor_src} -> {cursor_dst}")
        return
    if cursor_dst.exists():
        shutil.rmtree(cursor_dst)
    shutil.copytree(cursor_src, cursor_dst)
    agents_src = root / "agents.md"
    if agents_src.exists():
        shutil.copy2(agents_src, target / "agents.md")


def sync_rules(root: Path, target: Path, platforms: set[str], dry_run: bool) -> None:
    rules_dir = root / ".cursor" / "rules"
    agents_md = (root / "agents.md").read_text(encoding="utf-8")

    global_sections: list[str] = []
    contextual: list[tuple[str, dict[str, Any], str]] = []

    for mdc in sorted(rules_dir.glob("*.mdc")):
        meta, body = read_mdc(mdc)
        always = str(meta.get("alwaysApply", "false")).lower() == "true"
        globs = meta.get("globs")
        name = mdc.stem

        if always:
            global_sections.append(f"## {name}\n\n{body.strip()}\n")
        elif globs:
            contextual.append((name, meta, body))

    if platforms & {"copilot", "claude", "antigravity"}:
        agents_out = agents_md.strip() + "\n"
        write_file(target / "AGENTS.md", agents_out, dry_run)

    if "copilot" in platforms:
        copilot_parts = [
            "# RPE Harness — Instruções Copilot\n",
            "> Gerado automaticamente a partir de `.cursor/rules/` e `agents.md`. Não edite manualmente.\n",
            agents_md.strip(),
            "\n",
        ]
        copilot_parts.extend(global_sections)
        write_file(
            target / ".github" / "copilot-instructions.md",
            "\n".join(copilot_parts) + "\n",
            dry_run,
        )

        for name, meta, body in contextual:
            apply_to = globs_to_apply_to(meta.get("globs"))
            desc = meta.get("description", name)
            fm_lines = ["---", f'applyTo: "{apply_to}"', f'description: "{desc}"', "---"]
            fm = "\n".join(fm_lines) + "\n"
            write_file(
                target / ".github" / "instructions" / f"{name}.instructions.md",
                fm + body.strip() + "\n",
                dry_run,
            )

    if "claude" in platforms:
        claude_lines = [
            "# RPE Harness — Claude Code\n",
            "> Gerado automaticamente a partir do SSOT `.cursor/`.\n",
            "\n@AGENTS.md\n",
        ]
        for mdc in sorted(rules_dir.glob("*.mdc")):
            meta, body = read_mdc(mdc)
            if str(meta.get("alwaysApply", "false")).lower() == "true":
                claude_lines.append(f"\n## {mdc.stem}\n\n{body.strip()}\n")

        write_file(target / "CLAUDE.md", "\n".join(claude_lines) + "\n", dry_run)

        for name, meta, body in contextual:
            paths = globs_to_paths(meta.get("globs"))
            fm = format_frontmatter({"paths": paths})
            write_file(
                target / ".claude" / "rules" / f"{name}.md",
                fm + body.strip() + "\n",
                dry_run,
            )


def sync_agents(root: Path, target: Path, platforms: set[str], dry_run: bool) -> None:
    agents_dir = root / ".cursor" / "agents"
    antigravity_index: list[str] = [
        "# RPE Harness — Agentes\n",
        "> Gerado automaticamente. Invocar agentes conforme o editor.\n",
        "\n| Agente | Descrição | Readonly |\n|---|---|---|\n",
    ]

    for agent_file in sorted(agents_dir.glob("*.md")):
        content = agent_file.read_text(encoding="utf-8")
        meta, body = parse_frontmatter(content)
        name = meta.get("name", agent_file.stem)
        description = meta.get("description", "")
        readonly = str(meta.get("readonly", "false")).lower() == "true"
        is_background = str(meta.get("is_background", "false")).lower() == "true"
        model = meta.get("model", "")

        if "copilot" in platforms:
            copilot_meta: dict[str, Any] = {
                "name": name,
                "description": description,
            }
            if model:
                copilot_meta["model"] = model
            if is_background:
                copilot_meta["background"] = True
            if readonly:
                copilot_meta["tools"] = ["read", "search", "usages"]
            fm = format_frontmatter(copilot_meta)
            write_file(
                target / ".github" / "agents" / f"{name}.agent.md",
                fm + body.strip() + "\n",
                dry_run,
            )

        if "claude" in platforms:
            claude_meta: dict[str, Any] = {
                "name": name,
                "description": description,
            }
            if model:
                claude_meta["model"] = model
            if is_background:
                claude_meta["background"] = True
            claude_meta["permissionMode"] = "plan" if readonly else "default"
            fm = format_frontmatter(claude_meta)
            write_file(
                target / ".claude" / "agents" / f"{name}.md",
                fm + body.strip() + "\n",
                dry_run,
            )

        if "antigravity" in platforms:
            antigravity_index.append(
                f"| `{name}` | {description} | {'sim' if readonly else 'não'} |\n"
            )
            ag_meta = {"name": name, "description": description, "readonly": readonly}
            fm = format_frontmatter(ag_meta)
            write_file(
                target / ".agents" / "agents" / f"{name}.md",
                fm + body.strip() + "\n",
                dry_run,
            )

    if "antigravity" in platforms:
        write_file(
            target / ".agents" / "agents.md",
            "".join(antigravity_index) + "\n",
            dry_run,
        )


def sync_commands(root: Path, target: Path, platforms: set[str], dry_run: bool) -> None:
    commands_dir = root / ".cursor" / "commands"

    for cmd_file in sorted(commands_dir.glob("*.md")):
        content = cmd_file.read_text(encoding="utf-8")
        meta, body = parse_frontmatter(content)
        name = cmd_file.stem
        if meta:
            name = meta.get("name", name)
            description = meta.get("description", f"Comando {name}")
        else:
            description = f"Comando {name}"
            body = content

        if "copilot" in platforms:
            fm = format_frontmatter({"name": name, "description": description, "agent": "agent"})
            write_file(
                target / ".github" / "prompts" / f"{name}.prompt.md",
                fm + body.strip() + "\n",
                dry_run,
            )

        if "claude" in platforms:
            fm = format_frontmatter(
                {
                    "name": name,
                    "description": description,
                    "disable-model-invocation": True,
                }
            )
            skill_body = f"# {name.replace('-', ' ').title()}\n\n{body.strip()}\n"
            write_file(
                target / ".claude" / "skills" / name / "SKILL.md",
                fm + skill_body,
                dry_run,
            )

        if "antigravity" in platforms:
            fm = format_frontmatter({"name": name, "description": description})
            write_file(
                target / ".agents" / "workflows" / f"{name}.md",
                fm + body.strip() + "\n",
                dry_run,
            )


def sync_skills(root: Path, target: Path, platforms: set[str], dry_run: bool) -> None:
    skills_src = root / ".cursor" / "skills"
    platform_dirs = {
        "copilot": target / ".github" / "skills",
        "claude": target / ".claude" / "skills",
        "antigravity": target / ".agents" / "skills",
    }

    for platform in platforms:
        if platform not in platform_dirs:
            continue
        dst_base = platform_dirs[platform]
        for skill_dir in sorted(skills_src.iterdir()):
            if not skill_dir.is_dir():
                continue
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.exists():
                continue
            dst = dst_base / skill_dir.name
            # Skip if command skill already created for claude (commands take precedence name collision)
            if platform == "claude" and (dst / "SKILL.md").exists():
                meta, _ = parse_frontmatter((dst / "SKILL.md").read_text(encoding="utf-8"))
                if str(meta.get("disable-model-invocation", "")).lower() == "true":
                    continue
            if dry_run:
                print(f"[dry-run] copy skill {skill_dir} -> {dst}")
                continue
            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(skill_dir, dst)


def sanitize_mcp_json(content: str) -> str:
    """Remove JSON comments and trailing commas."""
    lines = []
    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        # Remove inline // comments (not inside strings — good enough for our mcp.json)
        if "//" in line:
            line = re.sub(r"\s//.*$", "", line)
        lines.append(line)
    cleaned = "\n".join(lines)
    cleaned = re.sub(r",(\s*[}\]])", r"\1", cleaned)
    return cleaned


def sync_hooks(root: Path, target: Path, platforms: set[str], dry_run: bool) -> None:
    hooks_src = root / ".cursor" / "hooks"
    hooks_dst = target / "scripts" / "ai-hooks"

    if dry_run:
        print(f"[dry-run] copy hooks {hooks_src} -> {hooks_dst}")
    else:
        if hooks_dst.exists():
            shutil.rmtree(hooks_dst)
        shutil.copytree(hooks_src, hooks_dst)

    hooks_json_path = root / ".cursor" / "hooks.json"
    if not hooks_json_path.exists():
        return

    raw = hooks_json_path.read_text(encoding="utf-8")
    cursor_hooks = json.loads(raw).get("hooks", {})

    pre_edit_cmds = cursor_hooks.get("onPreEdit", [])
    post_edit_cmds = cursor_hooks.get("onPostEdit", [])
    stop_cmds = cursor_hooks.get("stop", [])

    def map_command(entry: dict[str, str]) -> dict[str, Any]:
        cmd = entry.get("command", "")
        cmd = cmd.replace(".cursor/hooks/", "scripts/ai-hooks/")
        return {"type": "command", "command": cmd, "timeout": 30}

    copilot_hooks = {
        "hooks": {
            "PreToolUse": [map_command(c) for c in pre_edit_cmds],
            "PostToolUse": [map_command(c) for c in post_edit_cmds],
            "Stop": [map_command(c) for c in stop_cmds],
        }
    }

    if "copilot" in platforms:
        write_file(
            target / ".github" / "hooks" / "rpe-guards.json",
            json.dumps(copilot_hooks, indent=2) + "\n",
            dry_run,
        )

    if "claude" in platforms:
        claude_settings = {
            "hooks": {
                "PreToolUse": [
                    {
                        "matcher": "Write|Edit",
                        "hooks": [map_command(c) for c in pre_edit_cmds],
                    }
                ],
                "PostToolUse": [map_command(c) for c in post_edit_cmds],
                "Stop": [map_command(c) for c in stop_cmds],
            }
        }
        write_file(
            target / ".claude" / "settings.json",
            json.dumps(claude_settings, indent=2) + "\n",
            dry_run,
        )

    # Git pre-commit fallback for secret scanner
    pre_commit = cursor_hooks.get("onPreCommit", [])
    if pre_commit and not dry_run:
        git_hooks = target / ".git" / "hooks" / "pre-commit"
        if (target / ".git").exists():
            scanner = hooks_dst / "guards" / "secret-scanner.sh"
            hook_content = f"#!/bin/bash\nbash \"$(git rev-parse --show-toplevel)/scripts/ai-hooks/guards/secret-scanner.sh\"\n"
            git_hooks.parent.mkdir(parents=True, exist_ok=True)
            git_hooks.write_text(hook_content, encoding="utf-8")
            git_hooks.chmod(0o755)
    elif pre_commit and dry_run:
        print("[dry-run] install git pre-commit hook for secret-scanner")


def sync_mcp(root: Path, target: Path, platforms: set[str], dry_run: bool) -> None:
    mcp_src = root / ".cursor" / "mcp.json"
    if not mcp_src.exists():
        return

    cleaned = sanitize_mcp_json(mcp_src.read_text(encoding="utf-8"))
    try:
        json.loads(cleaned)
    except json.JSONDecodeError as exc:
        print(f"WARN: mcp.json inválido após sanitização: {exc}", file=sys.stderr)
        return

    if "copilot" in platforms:
        write_file(target / ".vscode" / "mcp.json", cleaned + "\n", dry_run)

    if "claude" in platforms:
        write_file(target / ".mcp.json", cleaned + "\n", dry_run)


def run_sync(
    target: Path,
    platforms: list[str],
    dry_run: bool = False,
) -> None:
    root = kit_root()
    platform_set = set(platforms)

    if "cursor" in platform_set:
        sync_cursor(root, target, dry_run)

    non_cursor = platform_set - {"cursor"}
    if non_cursor:
        sync_rules(root, target, non_cursor, dry_run)

    if non_cursor & {"copilot", "claude", "antigravity"}:
        sync_agents(root, target, non_cursor, dry_run)
        sync_commands(root, target, non_cursor, dry_run)
        sync_skills(root, target, non_cursor, dry_run)
        sync_hooks(root, target, non_cursor, dry_run)
        sync_mcp(root, target, non_cursor, dry_run)


def main() -> int:
    parser = argparse.ArgumentParser(description="RPE Harness multi-IDE sync")
    parser.add_argument("target", type=Path, help="Diretório alvo")
    parser.add_argument(
        "--platforms",
        default="cursor,copilot,claude,antigravity",
        help="Plataformas separadas por vírgula",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--command",
        default="all",
        choices=["all", "rules", "agents", "commands", "skills", "hooks", "mcp", "cursor"],
        help="Operação de sync",
    )
    args = parser.parse_args()

    platforms = [p.strip() for p in args.platforms.split(",") if p.strip()]
    target = args.target.resolve()
    root = kit_root()
    platform_set = set(platforms)

    if args.command == "all":
        run_sync(target, platforms, args.dry_run)
    elif args.command == "cursor":
        if "cursor" in platform_set:
            sync_cursor(root, target, args.dry_run)
    elif args.command == "rules":
        sync_rules(root, target, platform_set - {"cursor"}, args.dry_run)
    elif args.command == "agents":
        sync_agents(root, target, platform_set - {"cursor"}, args.dry_run)
    elif args.command == "commands":
        sync_commands(root, target, platform_set - {"cursor"}, args.dry_run)
    elif args.command == "skills":
        sync_skills(root, target, platform_set - {"cursor"}, args.dry_run)
    elif args.command == "hooks":
        sync_hooks(root, target, platform_set - {"cursor"}, args.dry_run)
    elif args.command == "mcp":
        sync_mcp(root, target, platform_set - {"cursor"}, args.dry_run)

    return 0


if __name__ == "__main__":
    sys.exit(main())
