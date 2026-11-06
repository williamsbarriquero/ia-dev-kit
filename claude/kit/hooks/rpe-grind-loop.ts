/**
 * Stop: loop de auto-correção do UltraWork (TDD Grinder).
 *
 * Só atua com `Modo: ultrawork` em .rpe/scratchpad.md. Roda o comando de testes
 * e libera o fim do turno apenas com exit 0 e `ALL_TESTS_PASSED: true` no scratchpad.
 * Senão devolve `decision: "block"` e o Claude continua. O contador de continuações
 * seguidas fica em .rpe/state/ e zera quando a cadeia recomeça
 * (`stop_hook_active: false`). No limite, ou no sucesso, o hook desarma o modo.
 *
 * Overrides por ambiente (chave `env` do settings.json):
 *   RPE_TEST_COMMAND      comando de testes (padrão: detectado pelo manifest)
 *   RPE_TEST_TIMEOUT_MS   timeout do comando (padrão 120000)
 *   RPE_GRIND_MAX         limite de continuações seguidas (padrão 5)
 */
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { emit, projectDir, readInput, runHook } from "./lib/hook-io.ts";

const ARMED = /^(\s*-\s*\*\*Modo\*\*\s*:\s*)ultrawork\b/im;
const PASSED = /ALL_TESTS_PASSED\**\s*:\s*\**\s*true\b/i;

export function isArmed(scratchpad: string): boolean {
  return ARMED.test(scratchpad);
}

export function scratchpadPassed(scratchpad: string): boolean {
  return PASSED.test(scratchpad);
}

export function disarm(scratchpad: string): string {
  return scratchpad.replace(ARMED, "$1concluido");
}

function hasNpmTestScript(root: string): boolean {
  try {
    const pkg = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
    const test = pkg?.scripts?.test;
    return typeof test === "string" && !/no test specified/.test(test);
  } catch {
    return false;
  }
}

export function detectTestCommand(root: string): string | null {
  if (process.env.RPE_TEST_COMMAND) return process.env.RPE_TEST_COMMAND;
  if (hasNpmTestScript(root)) return "npm test --silent";
  if (existsSync(join(root, "go.mod"))) return "go test ./...";
  if (existsSync(join(root, "gradlew"))) return "./gradlew test";
  if (existsSync(join(root, "mvnw"))) return "./mvnw test";
  if (existsSync(join(root, "pom.xml"))) return "mvn test";
  return null;
}

interface TestRun {
  command: string;
  exitCode: number;
  tail: string;
}

function runTests(root: string): TestRun | null {
  const command = detectTestCommand(root);
  if (!command) return null;
  const result = spawnSync(command, {
    shell: true,
    cwd: root,
    encoding: "utf8",
    timeout: Number(process.env.RPE_TEST_TIMEOUT_MS) || 120_000,
  });
  const output = `${result.stdout ?? ""}${result.stderr ?? ""}`.trim().split("\n").slice(-30).join("\n");
  return { command, exitCode: result.status ?? 1, tail: output.slice(-2000) };
}

export function continuationReason(run: TestRun | null, passedFlag: boolean, iteration: number, max: number): string {
  let reason: string;
  if (run && run.exitCode === 0 && !passedFlag) {
    reason = `Testes passaram (${run.command}, exit 0), mas ALL_TESTS_PASSED não é true em .rpe/scratchpad.md. Atualize o scratchpad antes de encerrar.`;
  } else {
    const details = run ? ` Comando: ${run.command}, exit ${run.exitCode}.\nÚltimas linhas:\n${run.tail}` : "";
    reason = `UltraWork: testes falhando ou scratchpad incompleto.${details}\nCorrija a implementação, rode os testes e atualize ALL_TESTS_PASSED no scratchpad.`;
  }
  const prefix = `[grind-loop ${iteration}/${max}] `;
  if (iteration >= 3) {
    return `${prefix}Várias iterações sem sucesso: revise a abordagem (diagnósticos LSP, type-check, premissas da spec) antes de insistir. ${reason}`;
  }
  return prefix + reason;
}

function main(): void {
  const input = readInput();
  const root = projectDir(input);
  // Fora de .claude/: o Claude Code trata .claude/ como sensível e pede permissão a cada escrita do agente.
  const scratchpadPath = join(root, ".rpe", "scratchpad.md");
  if (!existsSync(scratchpadPath)) return;
  const scratchpad = readFileSync(scratchpadPath, "utf8");
  if (!isArmed(scratchpad)) return;

  const max = Number(process.env.RPE_GRIND_MAX) || 5;
  const stateDir = join(root, ".rpe", "state");
  const stateFile = join(stateDir, `grind-${input.session_id ?? "default"}.json`);
  let iterations = 0;
  if (input.stop_hook_active && existsSync(stateFile)) {
    iterations = Number(JSON.parse(readFileSync(stateFile, "utf8")).iterations) || 0;
  }

  const run = runTests(root);
  const passedFlag = scratchpadPassed(scratchpad);
  const testsOk = !run || run.exitCode === 0;

  if (passedFlag && testsOk) {
    writeFileSync(scratchpadPath, disarm(scratchpad));
    rmSync(stateFile, { force: true });
    emit({ systemMessage: `UltraWork concluído: ${run ? `${run.command} exit 0` : "sem runner detectado"} e ALL_TESTS_PASSED: true.` });
    return;
  }

  if (iterations >= max) {
    writeFileSync(scratchpadPath, disarm(scratchpad));
    rmSync(stateFile, { force: true });
    emit({
      systemMessage: `UltraWork: limite de ${max} iterações atingido sem suíte verde. Loop desarmado; a decisão volta para você.`,
    });
    return;
  }

  iterations += 1;
  mkdirSync(stateDir, { recursive: true });
  writeFileSync(stateFile, JSON.stringify({ iterations }));
  emit({ decision: "block", reason: continuationReason(run, passedFlag, iterations, max) });
}

if (import.meta.main) runHook(main);
