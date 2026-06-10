---
name: go-mastery
description: Advanced engineering and idiomatic practices in Go.
disable-model-invocation: true
---

# Go Mastery

## Idiomatic Go
- **Formatting**: Always format code using `gofmt` or `goimports`.
- **Naming Conventions**: Use `MixedCaps` or `mixedCaps` rather than underscores. Keep names short and concise. Interface names usually end in `-er` (e.g., `Reader`, `Writer`).
- **Simplicity**: Prefer simple, readable code over clever one-liners.

## Project Structure
Adopt the Standard Go Project Layout where appropriate:
- `cmd/`: Main applications for this project.
- `pkg/`: Library code that's ok to use by external applications.
- `internal/`: Private application and library code. This is enforced by the Go compiler.
- `api/`: OpenAPI/Swagger specs, JSON schema files, protocol definition files.

## Error Handling
- **Values**: Errors are just values. Handle them gracefully.
- **No Exceptions**: Avoid `panic` and `recover` except for truly unrecoverable errors during initialization.
- **Wrapping**: Use `fmt.Errorf("...: %w", err)` to wrap errors and add context while preserving the original error type. Use `errors.Is` and `errors.As` to inspect them.

## Concurrency
- **Goroutines**: Use goroutines for independent, concurrent execution. They are cheap.
- **Channels**: "Don't communicate by sharing memory; share memory by communicating." Use channels to pass data between goroutines safely.
- **Context**: Always pass `context.Context` as the first argument to functions that do I/O or take a long time. Use it for cancellation and timeouts.
- **Sync Package**: Use `sync.Mutex` or `sync.RWMutex` when sharing state is unavoidable and channels add too much complexity. Use `sync.WaitGroup` to wait for a collection of goroutines to finish.

## Pointers vs Values
- Pass by value (copies) by default.
- Pass by pointer when you need to modify the receiver, or when the struct is very large and copying it would be a performance issue.
- Avoid pointers to interfaces.
