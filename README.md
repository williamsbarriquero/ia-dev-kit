# RPE Harness — Agentic Dev Kit

O **RPE Harness** é um kit de desenvolvimento de IA de nível corporativo com **SSOT em `.cursor/`** e suporte multi-IDE via sync automático para Cursor, VS Code + GitHub Copilot, Claude Code e Antigravity. A baseline universal está em [agents.md](./agents.md).

Inspirado nos conceitos avançados do **Oh My OpenAgent**, este harness implementa roteamento por intenção (IntentGate), persistência de sessão (Boulder System), ganchos de ciclo de vida em 3 camadas, prompts otimizados por modelo e automação de testes iterativa (UltraWork).

---

## Suporte Multi-IDE

| Editor | Flag de instalação | Artefatos gerados |
|---|---|---|
| Cursor | `--platforms=cursor` | `.cursor/` |
| VS Code + Copilot | `--platforms=copilot` | `.github/copilot-instructions.md`, prompts, agents, skills, hooks |
| Claude Code | `--platforms=claude` | `CLAUDE.md`, `.claude/rules/`, agents, skills |
| Antigravity | `--platforms=antigravity` | `AGENTS.md`, `.agents/skills/`, workflows |
| Time misto | `--platforms=cursor,copilot,claude,antigravity` | todos acima |

Documentação: [multi-ide-quickstart.md](docs/multi-ide-quickstart.md) | [multi-ide-mapping.md](docs/multi-ide-mapping.md) | [authoring-guide.md](docs/authoring-guide.md)

---

## 🚀 Quick Start

```bash
# Instalação completa (todas as plataformas)
./scripts/install.sh /caminho/para/seu/projeto/

# Instalação seletiva
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=cursor
./scripts/install.sh /caminho/para/seu/projeto/ --platforms=copilot,claude

# Re-sync após atualização do kit
./scripts/sync-platforms.sh /caminho/para/seu/projeto/ --platforms=copilot

# Validação
./scripts/validate.sh && ./scripts/validate-sync.sh
```

O script gera artefatos específicos de cada editor a partir do SSOT `.cursor/` — não edite arquivos gerados manualmente no projeto alvo.

---

## 📂 Estrutura de Diretórios do Harness

O RPE Harness é modular e organizado de forma plana e limpa nas seguintes camadas:

```text
ai-dev-kit/
├── .cursor/
│   ├── rules/                       # Regras modulares (.mdc) aplicadas contextualmente (sem prefixo de números)
│   │   ├── rpe-identity.mdc         # Identidade básica do agente
│   │   ├── coding-standards.mdc     # Padrões de código limpo corporativo
│   │   ├── safety-guardrails.mdc    # Bloqueios a inputs perigosos e vazamento de chaves
│   │   ├── intent-routing.mdc       # Roteamento de intenções (IntentGate) e acionamento UltraWork
│   │   ├── interaction-standards.mdc# Formato padrão de respostas estruturadas dos agentes (OmO style)
│   │   ├── typescript.mdc           # Regras específicas de lint e tipagem do TypeScript
│   │   ├── git-conventions.mdc      # Padrão de escrita e commits Git
│   │   ├── testing-standards.mdc    # Padrão corporativo para unitários e mocks
│   │   ├── tdd-workflow.mdc         # Regras para conduzir o ciclo TDD
│   │   ├── code-review.mdc          # Regras para revisão estática de PRs
│   │   ├── qa-standards.mdc         # Regras para asserções e seletores resilientes em testes
│   │   ├── ultrawork.mdc            # Modo de desenvolvimento autônomo com auto-correção
│   │   └── database-migrations.mdc  # Regras para escrita de SQL segura e rollback
│   ├── agents/                      # Subagentes especializados (invocados via @ no Cursor)
│   │   ├── rpe-architect.md         # Planejador sem permissão de escrita
│   │   ├── rpe-developer.md         # Implementador com acesso a edição e bash
│   │   ├── rpe-reviewer.md          # Revisor estático de código
│   │   ├── rpe-security.md          # Especialista DevSecOps (NIST/OWASP/SLSA)
│   │   ├── rpe-tech-writer.md       # Especialista em escrita técnica e OpenAPI
│   │   ├── rpe-atlassian.md         # Especialista em Jira e Confluence
│   │   ├── rpe-sdet.md              # Automatizador de testes E2E e APIs
│   │   ├── rpe-qa-analyst.md        # Elaborador de plano de testes e BDD
│   │   ├── rpe-test-lead.md         # Líder do fluxo TDD unitário
│   │   └── rpe-tester.md            # Executor de testes unitários do TDD
│   ├── commands/                    # Comandos rápidos de prompt (invocados via @ no Chat)
│   │   ├── audit-security.md        # Varredura de credenciais e OWASP Top 10
│   │   ├── review-pr.md             # Auditoria geral de PRs
│   │   ├── validate-stack.md        # Pipeline local de lint e testes
│   │   ├── generate-test-cases.md   # Criação automática de testes de caminhos e limites
│   │   ├── generate-pr-description.md # Criação automática de descrições de PR a partir do git diff
│   │   ├── refine-story.md          # Refinamento de histórias Jira sob o método Três Amigos
│   │   ├── generate-mocks.md        # Geração rápida de dublês de teste MSW/WireMock
│   │   └── audit-logs-otel.md       # Auditoria de logs, OpenTelemetry e LGPD
│   ├── hooks/                       # Barreiras locais determinísticas executadas fora do LLM
│   │   ├── guards/                  # Bloqueios (secret-scanner e write-file-guard)
│   │   ├── transforms/              # Formatações automáticas pós-salvamento
│   │   └── continuations/           # Script grind-loop para auto-correção de testes
│   ├── skills/                      # Conhecimento técnico aprofundado sob demanda do agente
│   │   ├── hexagonal-architecture/  # Guia Ports & Adapters
│   │   ├── go-mastery/              # Go idiomático
│   │   ├── java-mastery/            # Java Moderno e JVM
│   │   ├── bdd-gherkin/             # Escrita de cenários BDD estáveis
│   │   └── ... (outras 9 skills de arquitetura, linguagens e QA)
│   ├── hooks.json                   # Registro central de ganchos do Cursor
│   └── mcp.json                     # Integração com APIs externas (Model Context Protocol)
├── scripts/                         # Ferramentas de ciclo de vida (install.sh, sync-platforms.sh, validate.sh)
│   ├── lib/                         # Motor de sync multi-IDE (rpe_sync.py + wrappers)
│   ├── install.sh                   # Instalação seletiva por plataforma
│   ├── sync-platforms.sh            # Orquestrador de sync
│   ├── validate.sh                  # Validação do SSOT
│   └── validate-sync.sh             # Validação de paridade multi-IDE
├── templates/                       # Templates padrão para criação de novos agentes, regras ou skills
└── agents.md                        # Baseline universal (gera AGENTS.md no projeto alvo)
```

---

## 📚 Documentação Completa

Para aprofundar seu conhecimento sobre o funcionamento e o ciclo de vida do harness, leia:

1.  [Guia Completo do Desenvolvedor](docs/harness-guide.md) — O manual prático contendo todas as tabelas de agentes, comandos e comandos de execução.
2.  [Quick Start Multi-IDE](docs/multi-ide-quickstart.md) — Instalação e equivalências por editor.
3.  [Pesquisa: Agentic Harness](docs/agentic-harness.md) — A base de fundamentação teórica de engenharia de contexto por trás deste harness.

---

## 🛠️ Contribuindo

Para adicionar novas regras, agentes ou skills a este kit de desenvolvimento, utilize sempre os padrões contidos na pasta `templates/` e lembre-se de rodar `./scripts/validate.sh && ./scripts/validate-sync.sh` localmente antes de submeter suas alterações.
