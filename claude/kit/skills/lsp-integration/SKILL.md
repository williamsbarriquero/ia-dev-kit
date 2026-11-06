---
name: lsp-integration
description: Uso da tool LSP do Claude Code (definição, referências, diagnósticos) para navegação e validação estática antes de rodar testes.
disable-model-invocation: true
---

# Engenharia de Contexto via LSP

A tool `LSP` do Claude Code consulta o language server do projeto: navega com precisão em bases grandes e reporta erros e avisos de compilação sem rodar suítes pesadas. Ela também reporta diagnósticos automaticamente depois de cada edição.

## Pré-requisito

A tool só fica ativa com um plugin de code intelligence instalado e o binário do language server no PATH. Exemplos:

| Stack | Plugin | Binário |
|-------|--------|---------|
| TypeScript / JavaScript | `typescript-lsp@claude-plugins-official` | `typescript-language-server` |
| Go | `gopls-lsp@claude-plugins-official` | `gopls` |
| Java | `jdtls-lsp@claude-plugins-official` | `jdtls` |

Instalação: `/plugin install <plugin>`. Sem plugin, use o type-check ou build da stack (rule `stack-baseline`) como validação estática.

## Diretrizes

1. **Ir para definição**
   * **Objetivo**: achar a implementação exata de uma função, classe, struct ou tipo.
   * **Quando usar**: sempre que encontrar um símbolo desconhecido. Prefira isso a busca de texto.

2. **Achar referências**
   * **Objetivo**: listar todos os usos de uma variável, classe ou método.
   * **Quando usar**: antes de mudar assinatura de método ou tipo estrutural, para prever breaking changes em outros pacotes.

3. **Diagnósticos**
   * **Objetivo**: ler erros de tipo, imports quebrados, variáveis não usadas e erros de sintaxe.
   * **Quando usar**: como primeira linha de defesa. Antes de rodar testes demorados, zere os erros acusados nos arquivos alterados.
