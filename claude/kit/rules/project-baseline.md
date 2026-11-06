# Baseline do projeto

`AGENTS.md` na raiz entra no contexto pelo import `@AGENTS.md` do `CLAUDE.md`. Não peça para anexá-lo.

Ao iniciar:

1. Use o baseline do `AGENTS.md`, que já está no contexto.
2. Se existir `_[PREENCHER]_`, preencha **Stack do Projeto**, **Arquitetura**, **Restrições** e **Verificação por Stack** antes de planejar ou codar. Se a raiz tiver `claude/kit/`, este é o repositório do kit: não altere esses placeholders.
3. Use manifests (`package.json`, `pom.xml`, `build.gradle`, `go.mod`), `.claude/harness-stacks.json` e o que o usuário descreveu. Repositório vazio: use o pedido. Não invente restrição de negócio. Se ela não estiver no pedido nem no código, deixe uma linha `_pendente_` e siga.
4. Não reescreva o resto do arquivo.

Agente somente leitura: leia e sinalize placeholder. Quem preenche é quem pode escrever (thread principal ou subagent `rpe-architect`).
