# RPE Harness — Agentic Dev Kit

O **RPE Harness** é um kit de desenvolvimento de IA de nível corporativo projetado para o Cursor IDE (e compatível com outras IDEs via especificação [agents.md](./agents.md)). Ele fornece uma infraestrutura de orquestração determinística que encapsula modelos de linguagem, mitigando alucinações e garantindo que o código gerado siga os padrões de arquitetura, segurança e qualidade da RPE.

Inspirado nos conceitos avançados do **Oh My OpenAgent**, este harness implementa roteamento por intenção (IntentGate), persistência de sessão (Boulder System), ganchos de ciclo de vida em 3 camadas, prompts otimizados por modelo e automação de testes iterativa (UltraWork).

---

## 🚀 Quick Start

A forma recomendada de instalar o RPE Harness em qualquer novo repositório alvo é executando o script de instalação automatizado fornecido na pasta `scripts/`:

```bash
./scripts/install.sh /caminho/para/seu/projeto/
```

O script criará a estrutura de diretórios necessária e copiará todas as regras modulares, agentes especialistas, comandos rápidos, hooks locais, skills e configurações de MCP para o seu projeto.

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
├── scripts/                         # Ferramentas de ciclo de vida (install.sh, validate.sh, update.sh)
├── templates/                       # Templates padrão para criação de novos agentes, regras ou skills
└── agents.md                        # Baseline universal para conformidade em multi-IDEs (Claude Code, Aider)
```

---

## 📚 Documentação Completa

Para aprofundar seu conhecimento sobre o funcionamento e o ciclo de vida do harness, leia:

1.  [Guia Completo do Desenvolvedor](docs/harness-guide.md) — O manual prático contendo todas as tabelas de agentes, comandos e comandos de execução.
2.  [Pesquisa: Agentic Harness](docs/agentic-harness.md) — A base de fundamentação teórica de engenharia de contexto por trás deste harness.

---

## 🛠️ Contribuindo

Para adicionar novas regras, agentes ou skills a este kit de desenvolvimento, utilize sempre os padrões contidos na pasta `templates/` e lembre-se de rodar `./scripts/validate.sh` localmente antes de submeter suas alterações.
