---
name: mcp-integration
description: Guia de integração e uso de ferramentas Model Context Protocol (MCP) no RPE Harness.
disable-model-invocation: true
---

# Integração e Ferramentas MCP

O Model Context Protocol (MCP) estende as capacidades dos agentes de IA com acesso a documentação, GitHub e Jira.

## Diretrizes de Uso

1. **Listar tools**: Consultar schema/descriptor antes de invocar qualquer tool MCP.
2. **Respeitar schemas**: Validar payload contra JSON Schema da tool.
3. **Não-destrutividade**: Nunca executar DELETE, DROP, force push ou operações irreversíveis sem aprovação explícita.
4. **Cache**: Evitar chamadas repetidas no mesmo turno para dados imutáveis.

## Servidores Configuráveis

Configuração em `.mcp.json` na raiz do projeto. Segredos via variáveis de ambiente (`${VAR}` ou `${VAR:-padrão}`), nunca no arquivo. Na primeira sessão o Claude Code pede aprovação de cada servidor de projeto. As tools aparecem como `mcp__<servidor>__<tool>`.

### context7

- **Objetivo**: Documentação atualizada de bibliotecas e frameworks.
- **Quando usar**: Dúvidas sobre API, configuração ou migração de dependências.

### mcp-github

- **Objetivo**: PRs, issues, checks de CI.
- **Quando usar**: Criar PR, ler reviews, diagnosticar falhas de pipeline.

### atlassian (opcional)

- **Objetivo**: Jira e Confluence via Atlassian Remote MCP (OAuth).
- **Quando usar**: subagent `rpe-atlassian` para ler/atualizar histórias, páginas e RFCs.
- **Configuração**: `mcp-remote` → `https://mcp.atlassian.com/v1/mcp` (ver `.mcp.json`).

### mcp-postgres (desabilitado por default)

- **Risco**: Acesso SQL direto. Habilitar somente com read-only e whitelist de schema.
- **Guard**: o hook `rpe-guard-mcp.ts` (`PreToolUse` em `mcp__.*`) bloqueia DROP/TRUNCATE/DELETE em massa.

## Agentes por Servidor

| Servidor | Agente principal |
|----------|------------------|
| context7 | Todos (documentação) |
| mcp-github | developer, reviewer, infra |
| atlassian | atlassian |
| mcp-postgres | dba (somente leitura) |
