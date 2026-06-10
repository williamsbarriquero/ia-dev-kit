/**
 * TDD Grinder - Continuation Hook
 * Intercepta stdin do Cursor com contexto de execução (conversation_id, status, loop_count)
 * Verifica .cursor/scratchpad.md por ALL_TESTS_PASSED: true
 */
import { readFileSync } from 'fs';
import { join } from 'path';

interface CursorContext {
  conversation_id?: string;
  status?: string;
  loop_count?: number;
}

async function main() {
  try {
    // Read context from stdin
    const stdin = await new Response(Bun.stdin).text();
    const context: CursorContext = stdin ? JSON.parse(stdin) : {};
    
    const loopCount = context.loop_count || 1;
    const maxIterations = 5;

    // Verifica .cursor/scratchpad.md
    const scratchpadPath = join(process.cwd(), '.cursor', 'scratchpad.md');
    let allTestsPassed = false;
    
    try {
      const scratchpad = readFileSync(scratchpadPath, 'utf-8');
      if (scratchpad.includes('ALL_TESTS_PASSED: true')) {
        allTestsPassed = true;
      }
    } catch (e) {
      // scratchpad não existe ou não pôde ser lido
    }

    // Se os testes passaram, a tarefa está concluída e podemos encerrar a continuação.
    if (allTestsPassed) {
      console.log(JSON.stringify({}));
      process.exit(0);
    }

    if (loopCount >= maxIterations) {
      // Limite atingido
      console.log(JSON.stringify({
        error: `Limite de ${maxIterations} iterações atingido sem sucesso nos testes.`
      }));
      process.exit(1);
    }

    if (loopCount >= 3) {
      // Ativa Out-of-Band Advisor
      console.log(JSON.stringify({
        followup_message: "Múltiplas falhas detectadas (>3). Por favor, ative o Out-of-Band Advisor para análise profunda do erro, revise a abordagem atual."
      }));
      process.exit(0);
    }

    // Força reingresso no loop com prompt corretivo
    console.log(JSON.stringify({
      followup_message: "Testes falharam. ALL_TESTS_PASSED não é true no scratchpad. Por favor, revise a implementação, conserte os testes e atualize o scratchpad."
    }));
    
  } catch (error) {
    console.error("Erro no grind-loop:", error);
    process.exit(1);
  }
}

main();
