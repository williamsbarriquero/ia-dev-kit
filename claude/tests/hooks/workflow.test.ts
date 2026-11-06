import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runHook, tempProject } from "./helpers.ts";
import { slugFromPlan } from "../../kit/hooks/rpe-plan-to-specs.ts";
import { detectTestCommand, isArmed, scratchpadPassed } from "../../kit/hooks/rpe-grind-loop.ts";

const TEMPLATE = readFileSync(join(import.meta.dir, "..", "..", "kit", "scratchpad.template.md"), "utf8");

let project: ReturnType<typeof tempProject>;
beforeEach(() => {
  project = tempProject();
  mkdirSync(join(project.dir, ".rpe"), { recursive: true });
});
afterEach(() => project.cleanup());

const scratchpad = () => join(project.dir, ".rpe/scratchpad.md");
const arm = (passed: boolean) =>
  writeFileSync(
    scratchpad(),
    TEMPLATE.replace("- **Modo**: normal", "- **Modo**: ultrawork").replace(
      "- **ALL_TESTS_PASSED**: false",
      `- **ALL_TESTS_PASSED**: ${passed}`,
    ),
  );
const stop = (stop_hook_active: boolean, testCommand: string) =>
  runHook("rpe-grind-loop.ts", { hook_event_name: "Stop", session_id: "s1", stop_hook_active }, project.dir, {
    RPE_TEST_COMMAND: testCommand,
  });

describe("rpe-grind-loop", () => {
  test("template do scratchpad começa desarmado e com ALL_TESTS_PASSED false", () => {
    expect(isArmed(TEMPLATE)).toBe(false);
    expect(scratchpadPassed(TEMPLATE)).toBe(false);
  });

  test("desarmado não faz nada, nem roda testes", () => {
    writeFileSync(scratchpad(), TEMPLATE);
    const run = stop(false, "touch ran.txt");
    expect(run.stdout).toBe("");
    expect(existsSync(join(project.dir, "ran.txt"))).toBe(false);
  });

  test("testes falhando continuam o turno com a saída do comando", () => {
    arm(false);
    const run = stop(false, "echo 'expected 2 got 3' && exit 1");
    expect(run.json?.decision).toBe("block");
    expect(run.json?.reason).toContain("[grind-loop 1/5]");
    expect(run.json?.reason).toContain("expected 2 got 3");
  });

  test("testes verdes sem ALL_TESTS_PASSED pedem a atualização do scratchpad", () => {
    arm(false);
    const run = stop(false, "true");
    expect(run.json?.decision).toBe("block");
    expect(run.json?.reason).toContain("ALL_TESTS_PASSED não é true");
  });

  test("sucesso libera o fim e desarma o modo", () => {
    arm(true);
    const run = stop(true, "true");
    expect(run.json?.decision).toBeUndefined();
    expect(run.json?.systemMessage).toContain("UltraWork concluído");
    expect(isArmed(readFileSync(scratchpad(), "utf8"))).toBe(false);
  });

  test("conta continuações seguidas, avisa a partir da 3ª e desarma no limite", () => {
    arm(false);
    const reasons = [stop(false, "false"), stop(true, "false"), stop(true, "false")].map((r) => r.json?.reason as string);
    expect(reasons[0]).toContain("[grind-loop 1/5]");
    expect(reasons[2]).toContain("[grind-loop 3/5]");
    expect(reasons[2]).toContain("revise a abordagem");
    stop(true, "false");
    stop(true, "false");
    const last = stop(true, "false");
    expect(last.json?.decision).toBeUndefined();
    expect(last.json?.systemMessage).toContain("limite de 5");
    expect(isArmed(readFileSync(scratchpad(), "utf8"))).toBe(false);
  });

  test("nova cadeia (stop_hook_active false) zera o contador", () => {
    arm(false);
    stop(false, "false");
    stop(true, "false");
    expect(stop(false, "false").json?.reason).toContain("[grind-loop 1/5]");
  });

  test("detecção do runner ignora package.json sem script de teste", () => {
    writeFileSync(join(project.dir, "package.json"), JSON.stringify({ scripts: { test: 'echo "Error: no test specified" && exit 1' } }));
    expect(detectTestCommand(project.dir)).toBeNull();
    writeFileSync(join(project.dir, "pom.xml"), "<project/>");
    expect(detectTestCommand(project.dir)).toBe("mvn test");
  });
});

describe("rpe-plan-to-specs", () => {
  test("slug a partir do título do plano", () => {
    expect(slugFromPlan("# Plano: Recuperação de Senha\n\n...")).toBe("recuperacao-de-senha");
    expect(slugFromPlan("sem título")).toBeNull();
  });

  test("injeta additionalContext com o estado da pasta da spec", () => {
    const input = { tool_name: "ExitPlanMode", tool_response: { plan: "# Plano: Login Social\n" } };
    let run = runHook("rpe-plan-to-specs.ts", input, project.dir);
    const context = run.json?.hookSpecificOutput?.additionalContext as string;
    expect(run.json?.hookSpecificOutput?.hookEventName).toBe("PostToolUse");
    expect(context).toContain("docs/specs/login-social/ ainda não existe");

    const dir = join(project.dir, "docs/specs/login-social");
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "feature.md"), "x");
    writeFileSync(join(dir, "technical.md"), "x");
    run = runHook("rpe-plan-to-specs.ts", input, project.dir);
    expect(run.json?.hookSpecificOutput?.additionalContext).toContain("já existe");
  });
});
