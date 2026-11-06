/**
 * PreToolUse (mcp__.*): bloqueia operações destrutivas enviadas a servidores MCP
 * (SQL de DROP/TRUNCATE, DELETE sem WHERE, ALTER ... DROP).
 */
import { denyPreToolUse, readInput, runHook } from "./lib/hook-io.ts";

export const BLOCKED_MCP: Array<[RegExp, string]> = [
  [/\bDROP\s+(?:DATABASE|TABLE|SCHEMA)\b/i, "DROP DATABASE/TABLE/SCHEMA"],
  [/\bTRUNCATE\s+TABLE\b/i, "TRUNCATE TABLE"],
  [/\bDELETE\s+FROM\s+[\w."`]+\s*(?:;|"|$)/i, "DELETE sem WHERE"],
  [/\bALTER\s+TABLE\s+\S+\s+DROP\b/i, "ALTER TABLE ... DROP"],
];

export function mcpBlockedReason(toolInput: unknown): string | null {
  const payload = JSON.stringify(toolInput ?? {});
  for (const [pattern, label] of BLOCKED_MCP) {
    if (pattern.test(payload)) return label;
  }
  return null;
}

function main(): void {
  const input = readInput();
  const reason = mcpBlockedReason(input.tool_input);
  if (reason) {
    denyPreToolUse(`RPE guard: operação MCP destrutiva bloqueada em ${input.tool_name} (${reason}). Exige execução manual com aprovação.`);
  }
}

if (import.meta.main) runHook(main);
