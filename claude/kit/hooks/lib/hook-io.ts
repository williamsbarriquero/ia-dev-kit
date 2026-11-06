/**
 * Utilitários compartilhados pelos hooks do RPE Harness (Claude Code).
 *
 * Protocolo: o Claude Code envia JSON no stdin. Para bloquear um PreToolUse o hook
 * imprime `hookSpecificOutput.permissionDecision: "deny"`; para continuar um Stop,
 * imprime `{"decision":"block","reason":...}`. Exit diferente de 0 e 2 é erro não
 * bloqueante (a ação segue), por isso os hooks não usam exit 1 para bloquear.
 */
import { appendFileSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";

export interface HookInput {
  session_id?: string;
  cwd?: string;
  hook_event_name?: string;
  permission_mode?: string;
  tool_name?: string;
  tool_input?: Record<string, unknown>;
  tool_response?: unknown;
  agent_id?: string;
  agent_type?: string;
  stop_hook_active?: boolean;
}

/** Subagents RPE que não podem alterar o repositório. */
export const READONLY_AGENTS = new Set([
  "rpe-reviewer",
  "rpe-security",
  "rpe-test-lead",
  "rpe-qa-analyst",
  "rpe-atlassian",
]);

export function readInput(): HookInput {
  const raw = readFileSync(0, "utf8");
  return raw.trim() ? (JSON.parse(raw) as HookInput) : {};
}

export function projectDir(input: HookInput): string {
  return process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
}

/** Caminho relativo ao projeto, ou null se o arquivo estiver fora dele. */
export function projectRelative(root: string, filePath: string): string | null {
  const absolute = isAbsolute(filePath) ? filePath : resolve(root, filePath);
  const rel = relative(resolve(root), absolute);
  if (rel === "" || rel.startsWith("..") || isAbsolute(rel)) return null;
  return rel.split("\\").join("/");
}

export function emit(payload: unknown): void {
  process.stdout.write(JSON.stringify(payload));
}

export function denyPreToolUse(reason: string): void {
  emit({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: reason,
    },
  });
}

export function appendLog(root: string, message: string): void {
  const file = join(root, ".rpe", "logs", "modifications.log");
  try {
    mkdirSync(dirname(file), { recursive: true });
    appendFileSync(file, `${new Date().toISOString()} ${message}\n`);
  } catch {
    // Log é auxiliar: falha de escrita não deve derrubar o hook.
  }
}

/** Executa o hook e transforma exceção em erro não bloqueante, visível no transcript. */
export function runHook(main: () => void): void {
  try {
    main();
  } catch (error) {
    process.stderr.write(`[rpe-hook] ${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
  }
}
