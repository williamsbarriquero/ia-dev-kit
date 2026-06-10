---
name: mcp-integration
description: Guia de integração e uso de ferramentas Model Context Protocol (MCP) no RPE Harness.
disable-model-invocation: true
---

# Integração e Ferramentas MCP

O Model Context Protocol (MCP) estende as capacidades dos agentes de IA, dando acesso direto e seguro a bancos de dados, ferramentas de busca e sistemas externos do ecossistema RPE.

## Diretrizes de Uso de Ferramentas
Todo agente de IA operando com MCP deve seguir estas regras:
1. **Listagem de Ferramentas**: Execute `list_tools` no início do ciclo caso precise descobrir quais recursos estão acoplados.
2. **Respeito a Schemas**: Analise o JSON Schema das ferramentas antes de disparar payloads para evitar erros de sintaxe ou chamadas inválidas.
3. **Não-Destrutibilidade**: Nunca execute comandos destrutivos (como delete de tabelas, encerramento de servidores ou commits em branch protegida) sem aprovação manual explícita do usuário.
4. **Cache & Minimização**: Evite chamar a mesma ferramenta repetidas vezes no mesmo turno. Salve o resultado em cache no contexto da conversa se o dado for imutável.

## Servidores MCP Suportados & Utilidades

### 1. `context7` (Análise Estrutural e Arquivos Complexos)
* **Objetivo**: Fazer análise profunda e de escopo estrutural em arquivos extensos e no workspace.
* **Quando usar**: Use quando precisar mapear dependências circulares, fluxos de herança, e compreender grandes fluxos arquiteturais de código de forma simplificada antes de alterar arquivos.

### 2. `mgrep` (Busca Multiline de Alta Performance)
* **Objetivo**: Executar buscas textuais complexas e estruturadas em múltiplos arquivos usando expressões regulares ou correspondência multilinhas de alto desempenho.
* **Quando usar**: Substitui buscas simples em pastas quando o padrão procurado está distribuído em mais de uma linha de código (ex: blocos de declaração de métodos ou declarações de classes).

### 3. Jira / Confluence (`mcp-jira`)
* **Objetivo**: Gerenciar tarefas ágeis e manter a documentação sincronizada.
* **Quando usar**: O agente `@rpe-atlassian` deve usar para atualizar status de histórias, ler especificações de negócio e registrar notas de release (RFCs).

### 4. GitHub / GitLab (`mcp-github`)
* **Objetivo**: Automatizar interações de controle de versão.
* **Quando usar**: Criar Pull Requests, ler reviews e logs de pipelines de CI/CD para diagnosticar falhas de compilação.
