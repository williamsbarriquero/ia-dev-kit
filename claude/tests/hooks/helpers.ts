import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export const HOOKS_DIR = join(import.meta.dir, "..", "..", "kit", "hooks");

export interface HookRun {
  status: number | null;
  stdout: string;
  stderr: string;
  json: Record<string, any> | null;
}

/** Roda um hook como o Claude Code faria: JSON no stdin, CLAUDE_PROJECT_DIR no ambiente. */
export function runHook(file: string, input: unknown, projectDir: string, env: Record<string, string> = {}): HookRun {
  const result = spawnSync("bun", ["run", join(HOOKS_DIR, file)], {
    input: JSON.stringify(input),
    cwd: projectDir,
    encoding: "utf8",
    env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir, ...env },
  });
  let json: Record<string, any> | null = null;
  try {
    json = result.stdout.trim() ? JSON.parse(result.stdout) : null;
  } catch {
    json = null;
  }
  return { status: result.status, stdout: result.stdout, stderr: result.stderr, json };
}

export function decision(run: HookRun): string | undefined {
  return run.json?.hookSpecificOutput?.permissionDecision;
}

export function tempProject(prefix = "rpe-hook-"): { dir: string; cleanup: () => void } {
  const dir = mkdtempSync(join(tmpdir(), prefix));
  return { dir, cleanup: () => rmSync(dir, { recursive: true, force: true }) };
}
