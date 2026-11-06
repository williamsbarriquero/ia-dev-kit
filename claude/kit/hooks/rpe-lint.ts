/**
 * PostToolUse (Write|Edit): formata e corrige lint do arquivo editado.
 * Usa só binários locais do projeto (sem `npx` baixando pacotes) e nunca bloqueia.
 * Sem caminho no payload, não faz nada (o hook do Cursor lintava o projeto inteiro).
 */
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { extname, join } from "node:path";
import { projectDir, projectRelative, readInput, runHook } from "./lib/hook-io.ts";

const NODE_EXTENSIONS = new Set([".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"]);

export interface LintCommand {
  bin: string;
  args: string[];
}

function onPath(bin: string): boolean {
  return spawnSync("sh", ["-c", `command -v ${bin}`], { encoding: "utf8" }).status === 0;
}

export function lintCommands(root: string, rel: string): LintCommand[] {
  const ext = extname(rel);
  const commands: LintCommand[] = [];
  if (NODE_EXTENSIONS.has(ext)) {
    const eslint = join(root, "node_modules", ".bin", "eslint");
    const prettier = join(root, "node_modules", ".bin", "prettier");
    if (existsSync(eslint)) commands.push({ bin: eslint, args: ["--fix", rel] });
    if (existsSync(prettier)) commands.push({ bin: prettier, args: ["--write", rel] });
  } else if (ext === ".go" && onPath("gofmt")) {
    commands.push({ bin: "gofmt", args: ["-w", rel] });
  }
  return commands;
}

function main(): void {
  const input = readInput();
  const filePath = String(input.tool_input?.file_path ?? "");
  if (!filePath) return;

  const root = projectDir(input);
  const rel = projectRelative(root, filePath);
  if (rel === null || rel.includes("node_modules/")) return;

  for (const { bin, args } of lintCommands(root, rel)) {
    spawnSync(bin, args, { cwd: root, encoding: "utf8", timeout: 60_000 });
  }
}

if (import.meta.main) runHook(main);
