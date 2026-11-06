/**
 * PreToolUse (Bash): bloqueia comandos destrutivos, aplica a política somente
 * leitura aos subagents RPE de revisão/auditoria e varre segredos antes de `git commit`.
 */
import { READONLY_AGENTS, denyPreToolUse, projectDir, readInput, runHook } from "./lib/hook-io.ts";
import { formatFindings, scanForCommit } from "./rpe-secret-scan.ts";

export const BLOCKED_COMMANDS: Array<[RegExp, string]> = [
  [/\brm\s+-(?:rf|fr)\s+[/~]/i, "rm -rf em caminho absoluto ou home"],
  [/\bcurl\s+.*\|\s*(?:ba)?sh\b/i, "download executado direto no shell (curl | sh)"],
  [/\bwget\s+.*\|\s*(?:ba)?sh\b/i, "download executado direto no shell (wget | sh)"],
  [/\bgit\s+push\s+.*--force\b/i, "git push --force"],
  [/\bgit\s+push\s+-f\b/i, "git push -f"],
  [/\bDROP\s+(?:DATABASE|TABLE)\b/i, "DROP DATABASE/TABLE"],
  [/\bTRUNCATE\s+TABLE\b/i, "TRUNCATE TABLE"],
];

/** Programas que um subagent somente leitura pode rodar (primeira palavra do segmento). */
const READONLY_PROGRAMS = new Set([
  "cat", "head", "tail", "wc", "ls", "tree", "pwd", "echo", "printf", "file", "stat",
  "grep", "egrep", "fgrep", "rg", "sort", "uniq", "cut", "diff", "jq", "find",
  "govulncheck", "osv-scanner", "trivy", "semgrep", "gitleaks",
]);

const READONLY_GIT = new Set([
  "diff", "log", "show", "status", "blame", "rev-parse", "merge-base", "ls-files",
  "shortlog", "describe", "grep", "branch",
]);

const READONLY_PACKAGE_MANAGER = /^(?:npm|pnpm|yarn)\s+(?:audit|ls|list|outdated|why)\b|^go\s+(?:list|vet|version)\b|^snyk\s+test\b/;

export function blockedReason(command: string): string | null {
  for (const [pattern, label] of BLOCKED_COMMANDS) {
    if (pattern.test(command)) return label;
  }
  return null;
}

function readonlySegmentAllowed(segment: string): boolean {
  const words = segment.trim().split(/\s+/);
  const [program, sub] = words;
  if (!program) return true;
  if (program === "git") {
    if (!sub || !READONLY_GIT.has(sub)) return false;
    if (sub === "branch") return !words.some((w) => /^-(?:[dDmMcCf]|-delete|-move|-copy|-force)$/.test(w));
    return true;
  }
  if (program === "find") return !words.some((w) => /^-(?:delete|exec|execdir|ok|fprint)/.test(w));
  if (READONLY_PACKAGE_MANAGER.test(segment.trim())) return true;
  return READONLY_PROGRAMS.has(program);
}

/** Motivo da recusa para subagent somente leitura, ou null se o comando só lê. */
export function readonlyViolation(command: string): string | null {
  if (/\$\(|`/.test(command)) return "substituição de comando";
  // Conteúdo entre aspas é argumento literal: `grep -E "a|b"` não é pipe nem redirecionamento.
  const unquoted = command.replace(/'[^']*'|"(?:[^"\\]|\\.)*"/g, "''");
  const withoutSafeRedirects = unquoted.replace(/\d?>\s*\/dev\/null|\d?>&\d/g, "");
  if (/>/.test(withoutSafeRedirects)) return "redirecionamento para arquivo";
  for (const segment of unquoted.split(/&&|\|\||;|\||\n/)) {
    if (/^\s*tee\b/.test(segment)) return "tee";
    if (!readonlySegmentAllowed(segment)) return `comando fora da lista de leitura: ${segment.trim()}`;
  }
  return null;
}

export function isGitCommit(command: string): { commit: boolean; all: boolean } {
  const match = command.match(/\bgit\s+commit\b([^;&|]*)/);
  if (!match) return { commit: false, all: false };
  return { commit: true, all: /\s(?:-[a-zA-Z]*a[a-zA-Z]*|--all)\b/.test(match[1]) };
}

function main(): void {
  const input = readInput();
  const command = String(input.tool_input?.command ?? "");
  if (!command) return;

  const blocked = blockedReason(command);
  if (blocked) {
    denyPreToolUse(`RPE guard: comando de alto risco bloqueado (${blocked}). Peça ao usuário para executá-lo manualmente se for intencional.`);
    return;
  }

  if (input.agent_type && READONLY_AGENTS.has(input.agent_type)) {
    const violation = readonlyViolation(command);
    if (violation) {
      denyPreToolUse(`RPE guard: o subagent ${input.agent_type} é somente leitura (${violation}).`);
      return;
    }
  }

  const commit = isGitCommit(command);
  if (commit.commit) {
    const findings = scanForCommit(projectDir(input), commit.all);
    if (findings.length > 0) {
      denyPreToolUse(
        `RPE secret scan: possíveis credenciais no commit. Remova-as (use variáveis de ambiente) e tente de novo:\n${formatFindings(findings)}`,
      );
    }
  }
}

if (import.meta.main) runHook(main);
