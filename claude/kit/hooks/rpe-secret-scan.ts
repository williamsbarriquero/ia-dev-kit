/**
 * Varre as linhas adicionadas no git por padrões de credenciais.
 *
 * Usado pelo rpe-guard-bash.ts antes de `git commit`. Também roda sozinho, por
 * exemplo num `.git/hooks/pre-commit`: `bun .claude/hooks/rpe-secret-scan.ts`
 * sai com 1 se encontrar segredo no que está staged.
 */
import { spawnSync } from "node:child_process";

export const SECRET_PATTERN =
  /(password|secret|api[_-]?key|token|AKIA[A-Z0-9]{16})\s*[:=]\s*['"][^'"]+['"]/i;

export interface SecretFinding {
  file: string;
  line: string;
}

function gitDiff(cwd: string, args: string[]): string {
  const result = spawnSync("git", ["diff", "--no-color", "-U0", ...args], { cwd, encoding: "utf8" });
  return result.status === 0 ? result.stdout : "";
}

/** Mascara o valor entre aspas para não repetir o segredo na saída. */
export function maskSecret(line: string): string {
  return line.replace(/(['"])[^'"]+\1/g, "$1***$1");
}

export function scanDiff(diff: string): SecretFinding[] {
  const findings: SecretFinding[] = [];
  let file = "";
  for (const line of diff.split("\n")) {
    if (line.startsWith("+++ ")) {
      file = line.replace(/^\+\+\+ (b\/)?/, "");
      continue;
    }
    if (line.startsWith("+") && SECRET_PATTERN.test(line)) {
      findings.push({ file, line: maskSecret(line.slice(1).trim()).slice(0, 160) });
    }
  }
  return findings;
}

/**
 * Linhas adicionadas no index. Com `includeWorkingTree` (commit com -a/--all)
 * também varre as alterações não staged de arquivos rastreados.
 */
export function scanForCommit(cwd: string, includeWorkingTree: boolean): SecretFinding[] {
  const diffs = [gitDiff(cwd, ["--cached"])];
  if (includeWorkingTree) diffs.push(gitDiff(cwd, []));
  return diffs.flatMap(scanDiff);
}

export function formatFindings(findings: SecretFinding[]): string {
  return findings.map((f) => `  ${f.file}: ${f.line}`).join("\n");
}

if (import.meta.main) {
  const findings = scanForCommit(process.cwd(), false);
  if (findings.length > 0) {
    process.stderr.write(`Possíveis segredos no commit:\n${formatFindings(findings)}\n`);
    process.exit(1);
  }
}
