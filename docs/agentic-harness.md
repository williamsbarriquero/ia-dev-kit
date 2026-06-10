# Arquitetura de Sistemas de Desenvolvimento Agentic e Engenharia de Contexto: Diretrizes para a Construção de um Kit de Desenvolvimento de IA no Cursor IDE

A transição histórica no desenvolvimento de software assistido por inteligência artificial (IA) consolidou uma mudança profunda de paradigma: a evolução de sistemas conversacionais reativos de chat de código para sistemas operacionais de desenvolvimento autônomo e de ciclo fechado, caracterizados pelo desenvolvimento agentic (*agentic development*). No centro dessa mudança está o conceito de *agent harness* (harness de agente), uma infraestrutura de controle determinístico projetada para encapsular modelos de linguagem de grande escala (LLMs), mitigando sua natureza probabilística inerente por meio de regras, ferramentas, ganchos (*hooks*), habilidades (*skills*) e barramentos estruturados de orquestração.

Para engenheiros de sistemas e arquitetos de plataformas que visam criar um kit de desenvolvimento de IA (*ai-dev-kit*) de nível corporativo voltado para o editor de código Cursor, o entendimento minucioso de sua arquitetura interna de execução, interfaces de extensão e limites físicos de tokens é imperativo. O Cursor estabeleceu-se como uma bifurcação (*fork*) de alto desempenho do VS Code, re-renderizando nativamente a interface do usuário em torno da IA em vez de simplesmente acoplar extensões laterais. Essa integração nativa permite a execução de fluxos de trabalho avançados por meio do Composer, do Background Agent e do BugBot, oferecendo suporte a uma seleção profunda de modelos de fronteira, como Claude 4.7, GPT-5.5, Gemini 2.5 Pro e modelos de baixa latência proprietários, como o Composer-1 e o Sonic.

---

## Fundamentos e Mecânica de Execução do Agent Harness

O *agent harness* opera como um mecanismo de controle de tempo de execução que intercepta, avalia e potencializa de forma determinística cada transição e ação executada pelo agente. Em vez de permitir que o modelo interaja diretamente com o sistema operacional de forma irrestrita, o *harness* atua como um invólucro determinístico em torno de um núcleo probabilístico (o LLM).

A execução segue um fluxo fechado e iterativo estruturado em nove componentes principais que garantem a estabilidade em ambientes de produção :

* **Motor de Loop (While-Loop):** O motor fundamental de execução que transforma o LLM de um gerador de texto de disparo único em um agente de execução contínua. O loop de controle avalia as instruções do prompt de sistema, decide quais ferramentas invocar, executa-as em um ambiente controlado e alimenta os resultados de volta para a janela de contexto, iterando até atingir um critério de parada ou um limite máximo de execução.


* **Gerenciamento de Contexto:** Processo responsável por monitorar o crescimento da árvore de conversação e aplicar algoritmos de compactação semântica assim que o consumo de tokens atinge o limiar crítico de 80% a 90% do limite total do modelo. A decisão de compactação envolve a escolha de reterm as mensagens recentes em formato integral e resumir as interações passadas. O tratamento de entradas e saídas de ferramentas durante a compactação envolve um compromisso direto entre custo e precisão, onde a preservação integral é mais fiel e cara, enquanto a preservação exclusiva dos resultados economiza tokens, mas descarta o raciocínio intermediário.


* **Camada de Execução de Ferramentas (Tool Registry):** O mediador físico entre o agente e o ambiente externo. Esta camada gerencia a execução de comandos de shell, requisições de API, consultas a bancos de dados e manipulações de arquivos em ambientes de sandbox isolados, aplicando limites de tempo de execução (*timeouts*) e de permissões de acesso.


* **Orquestração e Gestão de Subagentes:** Mecanismo responsável por instanciar e monitorar trabalhadores secundários efêmeros com acessos dedicados a ferramentas e janelas de contexto restritas, evitando a contaminação e a saturação da sessão principal.


* **Habilidades Embutidas (Built-in Skills):** Comportamentos pré-definidos integrados nativamente pela plataforma (como comandos estruturados de Git, rotinas de revisão de Pull Requests e mecanismos de depuração automática) que reduzem a necessidade de o modelo improvisar lógicas complexas de controle.


* **Persistência de Sessão e Estado:** Gravação de estados de execução, checkpoints do sistema de arquivos e históricos de conversa em disco ou bancos de dados locais, permitindo a restauração completa das atividades em caso de falha ou suspensão.


* **Montagem de Prompt de Sistema (System Prompt Assembly):** Compilador dinâmico de contexto que injeta dados atualizados sobre o ambiente (como status do Git, metadados do sistema operacional, diretório ativo e lista de ferramentas disponíveis com suas respectivas permissões) imediatamente antes de cada envio ao modelo.


* **Ganchos de Ciclo de Vida (Lifecycle Hooks):** Pontos de extensão determinísticos que permitem interceptar e bloquear ações do agente com base em validações programáticas externas, operando de forma independente do contexto do LLM.


* **Camada de Segurança e Controle de Permissões:** Validador dinâmico que inspeciona sintaticamente e autoriza comandos de terminal ou modificações de arquivos antes de sua efetivação no ambiente de execução, suportando regras de aprovação humana interativa ou listas de permissões estáticas.



A otimização de tokens de contexto no Cursor baseia-se fortemente na ativação do *Symbol Index*. Ao realizar a varredura em segundo plano do repositório para construir uma tabela detalhada de símbolos (mapeando classes, métodos e dependências), o agente consulta o índice de símbolos em vez de realizar a leitura completa de arquivos de código. A conservação de tokens proporcionada por esse mecanismo pode ser descrita matematicamente. Se $C_{\text{raw}}$ representa o custo de tokens do carregamento de arquivos integrais na janela de contexto, e $C_{\text{index}}$ representa o custo do carregamento otimizado baseado no índice de símbolos, a economia de tokens é determinada de forma linear pelo coeficiente de eficiência de indexação $\eta$ :

$$C_{\text{index}} = (1 - \eta) \cdot C_{\text{raw}}$$

Onde o coeficiente de eficiência $\eta \in [0.30, 0.50]$, refletindo uma redução de 30% a 50% no consumo total de tokens de contexto do modelo durante tarefas complexas de leitura e navegação estrutural.

---

## O Paradigma "Thin Agent" e Orquestração de Multiagentes

A engenharia de sistemas agentic de alto desempenho rejeita a criação de agentes monolíticos de grande porte devido a problemas críticos de diluição de atenção e saturação de contexto. Em seu lugar, adota-se o padrão de "Agentes Leves" (*Thin Agent Pattern*), onde os trabalhadores são projetados para serem efêmeros, sem estado e com responsabilidades estritamente isoladas.

### Especificações Técnicas e de Limites Operacionais

Para garantir que os agentes permaneçam leves e altamente focados, são impostos limites estritos de tamanho de prompt, consumo de tokens e restrições de delegação no tempo de execução. A comparação estrutural entre os dois paradigmas de design de agentes está detalhada na tabela a seguir:

| Parâmetro Operacional | Padrão Agente Monolítico (Legacy) | Padrão Agente Leve (Thin Agent) |
| --- | --- | --- |
| **Linhas de Código de Instrução** | > 1.000 linhas | < 150 linhas (limite estrito) 

 |
| **Consumo de Tokens por Spawn** | ~24.000 tokens | ~2.700 tokens 

 |
| **Custo de Descoberta Semântica** | Elevado (> 8.000 caracteres) | 500 a 1.000 caracteres 

 |
| **Janela de Histórico e Estado** | Acumulada e compartilhada entre execuções | Zerada a cada spawn de instância secundária 

 |
| **Capacidade de Recursão** | Permitida (indutora de loops infinitos) | Bloqueada fisicamente no tempo de execução 

 |

### O Princípio de Exclusão Mútua de Ferramentas (Tool Boundary)

Uma das maiores fontes de falha em sistemas multiagentes é a quebra de papéis operacionais, onde um agente projetado para coordenação e planejamento decide escrever código diretamente no repositório, poluindo sua própria janela de contexto com detalhes de implementação. Para solucionar essa inconsistência, o *harness* aplica uma barreira física de exclusão mútua sobre as permissões de ferramentas disponíveis para cada papel :

* **Agente Coordenador (Main Thread):** Possui acesso exclusivo às ferramentas de delegação e gerenciamento, como `Task`, `TodoWrite` e `Read`. É fisicamente desprovido de ferramentas de modificação, não possuindo acesso a `Edit`, `Write` ou execução de terminal `Bash`. Esta restrição garante que o coordenador permaneça puramente na camada conceitual e estratégica.


* **Agente Executor (Sub-Agent/Worker):** Possui acesso total às ferramentas operacionais e de alteração física do sistema de arquivos, incluindo `Edit`, `Write` e `Bash`. É desprovido de ferramentas de delegação como `Task`, impedindo a criação de cadeias de sub-subagentes e loops infinitos de delegação.



### A Linha de Montagem de Desenvolvimento de Cinco Papéis

As demandas complexas de engenharia são processadas por meio de uma arquitetura de orquestração estruturada em uma linha de montagem com isolamento cognitivo rígido entre cinco papéis especializados :

* **Líder de Especialidade (*Lead - `*-lead*`):** Responsável exclusivo pela análise de requisitos e pela geração de um plano de arquitetura estruturado e atômico em formato JSON. Não realiza modificações diretas no código do repositório.


* **Desenvolvedor de Especialidade (*Developer - `*-developer*`):** Recebe o plano de arquitetura gerado pelo líder e implementa as modificações necessárias, focando estritamente na lógica interna das funções.


* **Revisor de Especialidade (*Reviewer - `*-reviewer*`):** Analisa o código desenvolvido em relação aos padrões de arquitetura e cobertura lógica do repositório, emitindo um relatório estruturado de aprovação ou rejeição técnica.


* **Líder de Testes (*Test Lead - `test-lead*`):** Determina as estratégias de teste adequadas (unitários, integração ou ponta a ponta) com base no plano de implementação e gera o plano de testes.


* **Tester de Especialidade (*Tester - `*-tester*`):** Codifica e executa os casos de teste especificados no plano de validação, emitindo relatórios de aprovação com base no código de saída das ferramentas de testes.



Para manter a consistência em modificações de grande escala, as transições entre esses papéis são controladas por uma máquina de estados padronizada de 16 fases, monitorada por ganchos de compactação (*compaction gates*) que bloqueiam a execução e forçam a consolidação de contexto sempre que o consumo acumulado ultrapassa o teto de 85% da capacidade suportada pelo modelo.

---

## Mecânica de Extensibilidade no Cursor: Commands, Skills, Hooks e Subagents

O Cursor IDE fornece uma arquitetura altamente modular para estender os recursos nativos do agente, permitindo a personalização de prompts, fluxos de validação de código e a criação de subagentes especializados que atuam diretamente sobre o espaço de trabalho.

### Custom Commands e Skills Dinâmicas

Os *Custom Commands* atuam como modelos de prompts salvos e reutilizáveis, projetados para tarefas repetitivas que não demandam a importação de novas ferramentas lógicas ou contexto mutável. Eles são armazenados no diretório `.cursor/commands/` como arquivos Markdown (`.md`) individuais e são invocados manualmente pelo desenvolvedor na barra de chat utilizando o caractere indicador `@` seguido do nome do arquivo.

As *Skills* (habilidades do agente), por outro lado, estendem a capacidade de execução do modelo por meio de instruções procedimentais dinâmicas, esquemas e scripts associados. Ao contrário das regras estáticas e sempre ativas, as habilidades são mantidas fora do contexto inicial do agente. Durante a execução, o agente analisa a lista de habilidades registradas no diretório `.cursor/skills/` apenas para reconhecimento de escopo e, quando identifica que uma habilidade é necessária para resolver a tarefa corrente, realiza o seu carregamento sob demanda para a janela de contexto ativo.

Cada habilidade é empacotada em uma pasta dedicada contendo um arquivo centralizador `SKILL.md` estruturado com o seguinte frontmatter YAML :

```yaml
---
name: s3-asset-deployer
description: "Habilidade utilizada para empacotar e implantar ativos estáticos em buckets de armazenamento S3."
disable-model-invocation: false
---
# S3 Asset Deployer
Executa rotinas de validação de integridade e sincronização de ativos no Amazon S3.

## Comandos Operacionais
* Validar acesso: `scripts/validate-s3-access.sh <bucket-name>`
* Sincronizar diretório: `scripts/sync-assets.sh <source-dir> <bucket-name>`

```

O parâmetro `disable-model-invocation` permite determinar se a habilidade pode ser ativada autonomamente pelo raciocínio interno do modelo (`false`) ou se deve ser executada exclusivamente quando o usuário a invoca de forma manual no editor de código através de comandos de barra `/` (`true`).

### Ganchos Determinísticos de Ciclo de Vida (Hooks)

Os *Hooks* (ganchos) fornecem barreiras e validações obrigatórias e determinísticas em torno das alterações realizadas pelo agente, agindo fora de sua janela de controle cognitivo. No Cursor, esses ganchos são registrados centralizadamente no arquivo `.cursor/hooks.json` localizado no diretório raiz do projeto (ou no diretório do usuário para aplicações globais). Os ganchos suportam a execução de scripts locais de shell, execução de rotinas em linguagens compiladas ou a injeção automatizada de prompts direcionados de auditoria.

Abaixo está o mapeamento dos ganchos nativos disponíveis e sua correspondência com eventos de ciclo de vida da IDE:

| Gancho de Evento | Momento de Disparo no Tempo de Execução | Aplicação Prática Recomendada |
| --- | --- | --- |
| `onPreEdit` | Disparado antes de o Composer persistir alterações fisicamente no sistema de arquivos. 

 | Bloqueio de alterações que violem regras de segurança estática do projeto. 

 |
| `onPostEdit` | Invocado após a gravação das alterações em disco pelo Composer. 

 | Execução de formatadores e linters automatizados sobre os arquivos modificados. 

 |
| `onPreCommit` | Executado imediatamente antes de o agente submeter um commit estruturado ao Git. 

 | Validação de chaves de API expostas de forma acidental e varredura de segredos. 

 |
| `onApprove` | Disparado quando o desenvolvedor clica em aprovar em um diff exibido no Composer. 

 | Coleta de métricas de aceitação e auditoria de alterações aceitas pelo desenvolvedor. 

 |
| `subagentStop` | Disparado quando uma sessão ativa de subagente secundário encerra sua execução. 

 | Injeção de prompts de revisão estética e validação de padrões de componentes. 

 |
| `stop` | Disparado ao término do loop principal de execução do agente. 

 | Verificação de cobertura de testes de regressão antes da entrega final. 

 |

O tempo de execução do Cursor apresenta otimizações severas de performance na infraestrutura de ganchos: a inicialização de comandos associados aos ganchos de ciclo de vida foi acelerada em 40 vezes, reduzindo a latência operacional a milissegundos, com suporte estendido para compatibilidade nativa de ganchos do Claude Code na interface de linha de comando (CLI).

### Criação de Subagentes Customizados

Para além dos subagentes nativos do sistema (como `Explore` para análise de código, `Bash` para execução de comandos e `Browser` para navegação web), o desenvolvedor pode expor especialistas adicionais estruturando arquivos de instrução no formato Markdown dentro da pasta `.cursor/agents/`. Os subagentes customizados utilizam o frontmatter YAML para parametrizar seu comportamento e contexto operacional de execução :

---

## name: schema-auditor
description: "Subagente especialista em analisar esquemas de banco de dados e arquivos de migração."
model: gpt-4o
readonly: true
is_background: false

Você é um DBA especialista encarregado de validar a integridade de migrações de banco de dados SQL.
Analise as alterações de arquivos de migração propostas e garanta que nenhuma operação de alteração
esteja realizando locks prolongados ou exclusão irreversível de colunas sem fallback de dados.

O parâmetro `readonly` garante que o subagente atue exclusivamente como um auditor consultivo no painel de chat, sendo fisicamente impedido de utilizar ferramentas de gravação ou escrita direta de código no espaço de trabalho. Já o parâmetro `is_background` define se a tarefa delegada ao subagente será processada em segundo plano de forma assíncrona enquanto o agente principal continua sua execução, ou se o agente principal deve suspender sua execução aguardando o retorno sequencial do subagente secundário.

---

## Integração de Contexto Externo via Model Context Protocol (MCP)

O *Model Context Protocol* (MCP) é um protocolo aberto e padronizado projetado para integrar fontes de contexto externas, recursos e ferramentas operacionais diretamente na interface do cliente de IA de maneira transparente e segura.

### Mecanismos de Transporte e Configuração

No Cursor, a conexão com servidores MCP pode ser efetuada localmente utilizando transporte baseado em entrada e saída padrão (`stdio`) ou remotamente por meio de conexões HTTP baseadas em *Server-Sent Events* (SSE). A declaração de servidores MCP ativos é unificada por meio do arquivo de manifesto JSON de configuração `mcp.json`, o qual pode ser declarado no escopo global do usuário em `~/.cursor/mcp.json` ou restrito ao repositório ativo no caminho `.cursor/mcp.json`.

A estrutura do arquivo `.cursor/mcp.json` exemplifica a declaração mista de transportes stdio locais e endpoints SSE baseados em rede :

```json
{
  "mcpServers": {
    "sqlite-local-db": {
      "command": "node",
      "args": [
        "/usr/local/bin/mcp-sqlite-server",
        "--db-path",
        "./data/development.db"
      ]
    },
    "enterprise-pipeline-api": {
      "url": "https://callbacks.omniapp.co/callback/mcp",
      "headers": {
        "Authorization": "Bearer ENV_MCP_ACCESS_TOKEN"
      }
    }
  }
}

```

### Limites Físicos e Restrições de Segurança

Embora a flexibilidade do protocolo MCP permita a conexão de dezenas de utilitários externos, existem restrições severas de infraestrutura e segurança que devem ser observadas no design do kit de ferramentas :

* **O Teto de 40 Ferramentas Ativas:** O Cursor impõe um limite técnico de segurança de aproximadamente 40 ferramentas expostas simultaneamente através de todos os servidores MCP configurados. Se esse número for excedido, o usuário receberá avisos no sistema e, de forma silenciosa, o agente perderá a visibilidade e o acesso a ferramentas adicionais. Esse limite existe porque cada descrição detalhada de parâmetros e funcionalidades das ferramentas consome tokens de contexto ativos. O excesso de esquemas inseridos no prompt de inicialização deteriora a acurácia do modelo de linguagem, reduzindo drasticamente sua capacidade de selecionar a ferramenta correta para a resolução do problema corrente.


* **Isolamento do Background Agent:** Atualmente, os serviços de execução assíncrona em nuvem do Cursor (*Background Agent*) operam de forma estritamente isolada e não possuem visibilidade ou capacidade de carregar servidores MCP declarados pelo desenvolvedor no arquivo local `.cursor/mcp.json`. O agente de nuvem é limitado de forma nativa às ferramentas de navegador integradas da IDE. Portanto, qualquer workflow que dependa de ferramentas MCP customizadas deve ser executado obrigatoriamente em sessões locais dentro do editor do desenvolvedor.


* **Vulnerabilidade de Credenciais e Confiança:** Servidores MCP operam com o nível completo de privilégios de autenticação configurados no ambiente do desenvolvedor. Recomenda-se desativar o modo de aprovação automática de ferramentas (Yolo Mode) para ferramentas que executem modificações destrutivas ou chamadas externas e priorizar o uso de credenciais e chaves de API com escopos limitados de leitura (*least privilege*).



---

## Normatização de Baselines e Regras de Engenharia de Contexto

Para garantir que o comportamento de codificação, sintaxe e padrões de projeto sejam seguidos pelo agente de IA de forma consistente e repetível ao longo de todo o repositório, é necessária a implantação de arquivos de regras estruturados.

### A Evolução do Mecanismo de Regras no Cursor

Historicamente, o Cursor utilizava um arquivo de texto unificado no diretório raiz denominado `.cursorrules`. Embora funcional, essa abordagem de arquivo único resultava em ineficiência severa de consumo de contexto, pois todas as instruções de banco de dados, frontend e DevOps eram inseridas no prompt do sistema de forma contínua em cada mensagem.

A arquitetura moderna do editor substituiu esse mecanismo pela introdução do diretório de regras `.cursor/rules/`, onde são declarados arquivos Markdown com a extensão `.mdc` contendo frontmatters YAML explícitos. Esse mecanismo permite segmentar as diretrizes por escopo, reduzindo o tráfego desnecessário de tokens.

Abaixo está o detalhamento comparativo das características e capacidades dos três formatos de governança de contexto atualmente suportados na indústria :

| Característica Estrutural | Regras Modernas `.cursor/rules/*.mdc` | Configuração `CLAUDE.md` | Padrão Universal `agents.md` |
| --- | --- | --- | --- |
| **Sintaxe do Arquivo** | Markdown com Frontmatter YAML 

 | Markdown Simples 

 | Markdown Simples 

 |
| **Escopo de Arquivos** | Filtros de Globs Granulares e Múltiplos 

 | Não aplicável (Nível de Repositório) 

 | Escopo por Nível de Diretório 

 |
| **Modos de Ativação** | Quatro Modos (Always, Auto, Agent, Manual) 

 | Sempre Ativo (Always-on) 

 | Sempre Ativo (Always-on) 

 |
| **Economia de Tokens** | Alta (Carregamento estrito sob demanda) 

 | Baixa (Saturação de contexto constante) 

 | Baixa (Saturação de contexto constante) 

 |
| **Compatibilidade** | Exclusivo do Cursor IDE 

 | Exclusivo do Claude Code 

 | Multi-IDE (Codex, Copilot, Cline, Aider) 

 |
| **Padrão de Prioridade** | Cascata por especificidade de Globs 

 | Cascata por proximidade de diretórios 

 | Cascata por proximidade de diretórios 

 |

No Cursor, a prioridade das regras aplicadas é resolvida em cascata determinística: regras globais de usuário (definidas nas configurações da IDE) possuem menor precedência e são sobrescritas pelas regras locais do repositório. Entre as regras locais, as regras estruturadas com padrões específicos de correspondência de arquivos (`globs`) possuem precedência direta sobre aquelas declaradas como de aplicação global (`alwaysApply: true`). O desenvolvedor pode auditar quais regras estão ativas para o arquivo corrente abrindo a paleta de comandos da IDE (Cmd/Ctrl + Shift + P) e executando a instrução **Cursor: Show Active Rules**.

### A Especificação agents.md e o Padrão Command-First

Para repositórios mantidos por equipes que utilizam ferramentas de IA heterogêneas de forma concorrente (como Cursor, Claude Code e GitHub Copilot), recomenda-se adotar o arquivo `agents.md` na raiz do repositório como a fonte canônica de governança de baselines. A especificação do `agents.md`, padronizada pela Agentic AI Foundation sob governança da Linux Foundation, estabelece as diretrizes ideais de escrita para que as políticas do repositório sejam seguidas de forma estrita pelos modelos de linguagem.

A escrita de regras eficazes baseia-se no princípio de que instruções qualitativas e descrições textuais abstratas destinadas a seres humanos (como "escreva código limpo" ou "seja cuidadoso com migrações") são rotineiramente ignoradas pelos agentes de IA durante a geração de código. As instruções devem ser estruturadas sob a abordagem **Command-First** e associadas a **Closure Definitions** (Definições de Conclusão baseadas em códigos de saída determinísticos) :

# Operational Policies for Coding Agents

## Verification Commands

* Linter validation: `ruff check. --fix`
* Formatting validation: `ruff format.`
* Core Test suite: `pytest -v`

## Definition of Done (DoD)

A task is physically considered complete if and only if all the following verification checkpoints exit with a success status code (0):

1. Execution of `ruff check.` returns exit code 0.
2. Execution of `pytest -v` completes with zero failures.
3. Git state is validated, and any modifications have been committed with conventional messaging.

Para dar suporte a ambientes de desenvolvimento heterogêneos com especificidades locais de rede ou variáveis de ambiente de teste personalizadas sem corromper as regras versionadas do repositório, a especificação prevê a leitura automatizada de um arquivo de substituição denominado `agents.override.md`. Esse arquivo deve ser mantido na lista de exclusões do controle de versão (`.gitignore`), permitindo ao desenvolvedor local customizar os comandos de compilação sem afetar a baseline do restante do time de engenharia.

A adoção consistente de baselines estruturadas sob os padrões de comando e regras descritos no `agents.md` gera um impacto positivo mensurável na eficiência de desenvolvimento. Dados de estudos de integração de agentes demonstram que repositórios assistidos por IA que possuem baselines configuradas apresentam uma **redução mediana de 28,64% no tempo de entrega final da tarefa** (*wall-clock time*) e uma **redução de 16,58% no consumo total de tokens de saída** do modelo de linguagem, reduzindo os custos operacionais de API e minimizando ciclos de depuração redundantes causados por alucinações e desalinhamento de contexto.

---

## Estrutura de Referência de um ai-dev-kit no Cursor

Com base nas especificações técnicas detalhadas, apresenta-se a arquitetura recomendada para a implantação de um kit de ferramentas de IA (*ai-dev-kit*) de alta performance no Cursor IDE. A infraestrutura baseia-se na consolidação de ferramentas determinísticas fora do contexto dos modelos de linguagem para orquestrar de forma consistente a criação, teste e entrega contínua de software.

```
meu-repositorio/
├──.cursor/
│   ├── agents/
│   │   ├── lead-architect.md        # Arquiteto de Sistemas (Read-only, sem permissão Bash)
│   │   └── code-executor.md         # Desenvolvedor de Software (Acesso total Edit/Bash)
│   ├── commands/
│   │   └── validate-pipeline.md     # Template de prompt para auditoria rápida de YAML
│   ├── hooks/
│   │   ├── audit-credentials.sh     # Gancho de auditoria estática pré-commit
│   │   └── grind-loop.ts            # Script Bun de controle iterativo de TDD (Stop Hook)
│   ├── rules/
│   │   ├── 00-stack-baseline.mdc    # Regra Global (Always Apply): Definições de versões da stack
│   │   ├── 01-api-routing.mdc       # Regra Inteligente (Agent Decision): Configurações HTTP/API
│   │   └── 02-test-standards.mdc    # Regra de Glob (Auto-Attached): Padrões de testes e mocks
│   ├── skill-library/
│   │   └── configure-cloud-vault.md # Habilidade Avançada (Biblioteca Nível 2): Gestão de segredos
│   ├── skills/
│   │   ├── pipeline-gateway/
│   │   │   └── SKILL.md             # Gateway de Skills (Nível 1): Roteamento inteligente de contexto
│   │   └── tdd-grinder/
│   │       └── SKILL.md             # BIOS de Habilidade (Nível 1): Orquestrador de testes iterativos
│   ├── hooks.json                   # Registro central de ganchos do ciclo de vida da IDE
│   └── mcp.json                     # Configuração local de servidores e portas MCP ativos
├── agents.md                        # Baseline de regras universais para multi-IDE
└── agents.override.md               # Sobrescritas locais específicas do desenvolvedor (Ignorado Git)

```

### O Gancho de Intercepção de Ciclo TDD (`grind-loop.ts`)

Para garantir a integridade da implementação, o kit de ferramentas implementa o padrão de *TDD Grinder* utilizando o gancho `stop` no arquivo `.cursor/hooks.json`. Este gancho avalia de forma determinística os resultados de testes e impede o encerramento do agente até que todas as asserções de qualidade sejam plenamente satisfeitas.

A abaixo está a declaração do registro de ganchos no arquivo `.cursor/hooks.json` :

```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": "bun run.cursor/hooks/grind-loop.ts"
      }
    ]
  }
}

```

O script TypeScript a seguir, hospedado no arquivo `.cursor/hooks/grind-loop.ts` e executado utilizando o ambiente de tempo de execução Bun, intercepta os dados do canal de entrada padrão (`stdin`), inspeciona a persistência do arquivo de notas (*scratchpad*) e emite a ordem de reingresso no loop de execução caso as asserções falhem :

```typescript
import { readFileSync, writeFileSync, existsSync } from "fs";

interface CursorStopHookInput {
  conversation_id: string;
  status: "completed" | "aborted" | "error";
  loop_count: number;
}

// Captura do contexto operacional enviado nativamente pela IDE via stdin
const rawInput = readFileSync(0, "utf-8");
const executionContext: CursorStopHookInput = JSON.parse(rawInput);
const MAX_PERMITTED_ITERATIONS = 5;

// Encerramento do ciclo caso o agente tenha sido abortado pelo usuário ou estourado o orçamento físico de iterações
if (executionContext.status!== "completed" || executionContext.loop_count >= MAX_PERMITTED_ITERATIONS) {
  console.log(JSON.stringify({}));
  process.exit(0);
}

const scratchpadPath = ".cursor/scratchpad.md";
const scratchpadContent = existsSync(scratchpadPath)
 ? readFileSync(scratchpadPath, "utf-8")
  : "";

// Avaliação semântica das asserções de testes anotadas pelo agente no scratchpad
if (scratchpadContent.includes("ALL_TESTS_PASSED: true")) {
  console.log(JSON.stringify({}));
} else {
  // Retorno estruturado forçando o reingresso e direcionamento do agente para nova iteração corretiva
  const nextIteration = executionContext.loop_count + 1;
  const promptPayload = {
    followup_message: `Os testes de regressão não atingiram 100% de sucesso. Execute o comando 'npm test' no terminal Bash, colete os erros do console e corrija o código de implementação. Não encerre a execução até que o campo 'ALL_TESTS_PASSED: true' seja adicionado ao arquivo ${scratchpadPath}.`
  };
  console.log(JSON.stringify(promptPayload));
}

```

Para modelar matematicamente a probabilidade de convergência bem-sucedida do loop de execução `$P(S)$` em função do número máximo de iterações permitidas `$n$` e da probabilidade de autocorreção em um único ciclo `$p$`, assume-se a independência estocástica entre tentativas sucessivas após a injeção do feedback estruturado do gancho:

$$P(S) = 1 - (1 - p)^n$$

Para um cenário real com taxa média de autocorreção por ciclo de depuração `$p = 0.65$` e limite orçamentário de iterações no kit de ferramentas configurado como `$n = 5$` :

$$P(S) = 1 - (1 - 0.65)^5 = 1 - (0.35)^5 = 1 - 0.00525 \approx 0.9947$$

Ou seja, a probabilidade final de convergência bem-sucedida do loop utilizando o gancho de ciclo de testes é de aproximadamente 99.47%, o que mitiga de forma extrema as chances de entrega de artefatos de código com regressões lógicas sintáticas.

### O Mecanismo de Recuperação de Deadlocks por Conselheiro Fora de Banda (Out-of-Band Advisor)

Caso o agente de codificação fique preso em um ciclo contínuo de erros de compilação repetitivos e falhe consecutivamente por mais de três iterações no mesmo ponto de verificação, o gancho de controle bloqueia a execução local e ativa um **Conselheiro Fora de Banda (Out-of-Band Advisor)**. O conselheiro é instanciado disparando uma chamada HTTP dedicada para uma API externa de um modelo de raciocínio de alto desempenho (como Gemini 1.5 Pro ou OpenAI o1) enviando apenas o histórico de alterações estruturais e o log de erros de compilação acumulado.

A resposta estruturada do conselheiro de raciocínio, contendo uma análise de desvio de rota lógica e uma sugestão de correção pragmática, é injetada de volta na sessão principal de desenvolvimento do Cursor como uma mensagem de sistema de alta prioridade. Esse fluxo quebra o viés de atenção do agente principal e o direciona a adotar uma abordagem alternativa de engenharia para solucionar o problema de linting de forma assertiva, evitando o esgotamento inútil de tokens de API.

### Integração Dinâmica de Recursos via Habilidades Gateway

O `ai-dev-kit` deve evitar a especificação manual e estática de endpoints e esquemas de payload de APIs em seus prompts. No lugar dessa prática, o desenvolvedor deve parametrizar habilidades de Gateway de Recursos locais com ferramentas baseadas no Model Context Protocol para realizar a descoberta sintática dinâmica em tempo real.

Abaixo está o exemplo de especificação de descoberta dinâmica hospedado no arquivo de regras de desenvolvimento de infraestrutura `.cursor/rules/01-api-discovery.mdc` :

---

## description: "Regra ativada ao gerar novos manifestos de implantação ou interagir com APIs de CI/CD"
globs: ["pipelines/**/*.yaml", "infra/**/*.tf"]
alwaysApply: false

# Diretrizes para Integração e Descoberta Dinâmica de Esquemas

## Ordem de Operações Obrigatória para Geração de Payloads

Para evitar falhas de compilação por uso de esquemas de API desatualizados ou caminhos incorretos de parâmetros, o agente é expressamente proibido de adivinhar nomes de propriedades ou estruturas de dados. Siga rigorosamente a sequência de execução abaixo:

1. **Validação de Contexto:** Antes de gerar qualquer recurso Terraform ou manifesto YAML, confirme o contexto ativo de conta e ambiente utilizando a ferramenta MCP `harness_get_context`.
2. **Autodescoberta de Esquema:** Utilize a ferramenta MCP `harness_describe` passando o identificador do recurso alvo para obter o JSON Schema atualizado diretamente da plataforma em tempo de execução.
3. **Validação e Geração:** Monte o payload ou manifesto de configuração utilizando os campos retornados pelo esquema e submeta-o ao validador sintático local antes de persistir as alterações.

Ao encadear essas ferramentas por meio do Gateway de Recursos, as habilidades mantêm-se leves, flexíveis e imunes a mudanças de infraestrutura externa, garantindo a perfeita integridade operacional das entregas de software do desenvolvedor.