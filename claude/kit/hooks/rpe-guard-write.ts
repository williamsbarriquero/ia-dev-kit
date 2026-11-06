/**
 * PreToolUse (Write|Edit|NotebookEdit): restringe a escrita por papel e avisa
 * sobre package.json. Arquivos protegidos de forma estática (.env, lockfiles,
 * CI, Dockerfile) ficam em permissions.deny/ask do settings.json, não aqui.
 */
import { basename } from "node:path";
import {
  READONLY_AGENTS,
  appendLog,
  denyPreToolUse,
  emit,
  projectDir,
  projectRelative,
  readInput,
  runHook,
} from "./lib/hook-io.ts";

/** O architect só grava o baseline e as specs aprovadas. */
export function architectMayWrite(rel: string): boolean {
  return rel === "AGENTS.md" || rel.startsWith("docs/specs/");
}

export type WriteDecision =
  | { kind: "allow" }
  | { kind: "deny"; reason: string }
  | { kind: "warn"; message: string };

export function decideWrite(root: string, filePath: string, agentType?: string): WriteDecision {
  const rel = projectRelative(root, filePath);
  // Fora do projeto (ex.: arquivo de plano do Plan Mode em ~/.claude/plans): não é escopo do harness.
  if (rel === null) return { kind: "allow" };

  if (agentType && READONLY_AGENTS.has(agentType)) {
    return { kind: "deny", reason: `o subagent ${agentType} é somente leitura` };
  }
  if (agentType === "rpe-architect" && !architectMayWrite(rel)) {
    return { kind: "deny", reason: "o rpe-architect só grava AGENTS.md e docs/specs/<slug>/" };
  }
  if (basename(rel) === "package.json" && !rel.includes("node_modules/")) {
    return { kind: "warn", message: `package.json alterado (${rel}): confirme se a mudança de dependências é intencional.` };
  }
  return { kind: "allow" };
}

function main(): void {
  const input = readInput();
  const filePath = String(input.tool_input?.file_path ?? input.tool_input?.notebook_path ?? "");
  if (!filePath) return;

  const root = projectDir(input);
  const decision = decideWrite(root, filePath, input.agent_type);
  if (decision.kind === "deny") {
    appendLog(root, `blocked ${input.tool_name} ${filePath} (${decision.reason})`);
    denyPreToolUse(`RPE guard: escrita bloqueada em ${filePath}: ${decision.reason}.`);
  } else if (decision.kind === "warn") {
    appendLog(root, `warned ${input.tool_name} ${filePath}`);
    emit({ systemMessage: `⚠️ ${decision.message}` });
  }
}

if (import.meta.main) runHook(main);
