/**
 * PostToolUse (ExitPlanMode): no momento em que o plano é aprovado, lembra a
 * regra plan-to-specs (spec antes do código) com o slug sugerido e o estado da pasta.
 */
import { existsSync } from "node:fs";
import { join } from "node:path";
import { emit, projectDir, readInput, runHook } from "./lib/hook-io.ts";

export function planText(input: { tool_input?: Record<string, unknown>; tool_response?: unknown }): string {
  const response = input.tool_response as Record<string, unknown> | undefined;
  return String(response?.plan ?? input.tool_input?.plan ?? "");
}

export function slugFromPlan(plan: string): string | null {
  const heading = plan.match(/^#\s+(.+)$/m)?.[1];
  if (!heading) return null;
  const slug = heading
    .replace(/^plano\s*[:—-]\s*/i, "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return slug || null;
}

export function specContext(root: string, slug: string | null): string {
  const base =
    "Plano aprovado. Regra plan-to-specs: se este plano for de feature (intent deep ou ultrawork), " +
    "a spec vem antes do código. Se docs/specs/<slug>/feature.md e technical.md não existirem, grave-os a partir de " +
    ".claude/templates/feature-spec.md e technical-spec.md com Status aprovado, informe os caminhos e pare antes de implementar. " +
    "Se já existirem, implemente a partir deles. Planos de correção rápida (intent quick) não geram spec.";
  if (!slug) return base;
  const dir = join(root, "docs", "specs", slug);
  const complete = existsSync(join(dir, "feature.md")) && existsSync(join(dir, "technical.md"));
  return `${base} Slug sugerido pelo título do plano: ${slug} (docs/specs/${slug}/ ${complete ? "já existe" : "ainda não existe"}).`;
}

function main(): void {
  const input = readInput();
  const root = projectDir(input);
  emit({
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: specContext(root, slugFromPlan(planText(input))),
    },
  });
}

if (import.meta.main) runHook(main);
