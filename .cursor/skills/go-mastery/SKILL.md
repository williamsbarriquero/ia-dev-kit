---
name: go-mastery
description: Engenharia avançada e práticas idiomáticas em Go.
disable-model-invocation: true
---

# Go Mastery

## Go Idiomático

- **Formatação**: Sempre formate o código com `gofmt` ou `goimports`.
- **Convenções de nomenclatura**: Use `MixedCaps` ou `mixedCaps` em vez de underscores. Mantenha nomes curtos e concisos. Nomes de interfaces costumam terminar em `-er` (ex.: `Reader`, `Writer`).
- **Simplicidade**: Prefira código simples e legível a one-liners inteligentes.

## Estrutura de Projeto

Adote o Standard Go Project Layout quando apropriado:

- `cmd/`: Aplicações principais do projeto.
- `pkg/`: Código de biblioteca que pode ser usado por aplicações externas.
- `internal/`: Código privado de aplicação e biblioteca. Isso é imposto pelo compilador Go.
- `api/`: Especificações OpenAPI/Swagger, arquivos JSON Schema, definições de protocolo.

## Tratamento de Erros

- **Valores**: Erros são apenas valores. Trate-os de forma adequada.
- **Sem exceções**: Evite `panic` e `recover`, exceto para erros verdadeiramente irrecuperáveis durante a inicialização.
- **Encapsulamento (wrapping)**: Use `fmt.Errorf("...: %w", err)` para encapsular erros e adicionar contexto, preservando o tipo original. Use `errors.Is` e `errors.As` para inspecioná-los.

## Concorrência

- **Goroutines**: Use goroutines para execução independente e concorrente. Elas são baratas.
- **Channels**: "Não comunique compartilhando memória; compartilhe memória comunicando." Use channels para passar dados entre goroutines com segurança.
- **Context**: Sempre passe `context.Context` como primeiro argumento em funções que fazem I/O ou demoram. Use-o para cancelamento e timeouts.
- **Pacote sync**: Use `sync.Mutex` ou `sync.RWMutex` quando compartilhar estado for inevitável e channels adicionarem complexidade demais. Use `sync.WaitGroup` para aguardar a conclusão de um conjunto de goroutines.

## Ponteiros vs Valores

- Passe por valor (cópias) por padrão.
- Passe por ponteiro quando precisar modificar o receiver ou quando a struct for muito grande e copiá-la causar problema de performance.
- Evite ponteiros para interfaces.
