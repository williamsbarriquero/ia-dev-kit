# Frontend (React / Next.js) — SSOT RPE

Conteúdo canônico para implementação e revisão frontend. Referenciado por `frontend-mastery` e `frontend-standards.mdc`.

## Perfil e filosofia

- Desenvolvimento **component-driven**, funcional e declarativo (SOLID, KISS, DRY).
- **Type safety** com TypeScript strict.
- Planejar em pseudocódigo antes de codificar; implementação completa, sem placeholders.
- Código legível antes de micro-otimização; early returns e guard clauses.
- UX com micro-interações sutis; animações devem reforçar, não distrair.

## Stack típica

- **React 18+** — hooks, componentes funcionais.
- **Next.js** — Server Components por padrão; App Router.
- **TypeScript** — strict mode.
- **Tailwind CSS** — utility-first; evitar CSS solto quando Tailwind cobre o caso.
- **shadcn/ui** + **Radix UI** — componentes acessíveis e composáveis.
- **TanStack Query** — estado de servidor.
- **Zustand** — estado global cliente (preferido sobre Context para escala).
- **React Hook Form** + **Zod** — formulários e validação.
- **Vitest** + **React Testing Library** — testes unitários/componente.
- **Cypress** ou **Playwright** — E2E.
- **Vite** / **esbuild** — build tooling (quando fora de Next.js).
- **Framer Motion** — animações quando o design system exigir.

## Arquitetura e estrutura

### Organização

- Diretórios em **kebab-case** (`components/auth-wizard/`).
- Estrutura de arquivo:
  1. Export principal (componente/função)
  2. Subcomponentes e helpers
  3. Conteúdo estático
  4. Types/interfaces

### Nomenclatura

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Componentes, tipos | PascalCase | `UserProfile`, `UserData` |
| Diretórios, arquivos | kebab-case | `user-profile.tsx` |
| Variáveis, funções, hooks | camelCase | `isLoading`, `useAuth` |
| Handlers de evento | prefixo `handle` | `handleClick`, `handleSubmit` |
| Booleanos | prefixo verbal | `isLoading`, `hasError`, `canSubmit` |

### Convenções de código

- Arquivos `*.tsx` → componentes React; `*.ts` → utilitários, tipos, configs.
- **Named exports** para utilitários; export default apenas para página/componente raiz quando o projeto exigir.
- **Imports** (ordem): React → terceiros → internos → relativos.
- Estilo: aspas simples, indent 2 espaços, `const` para imutáveis, optional chaining e nullish coalescing.
- Handlers nomeados com `handle*`; preferir `const fn = () =>` em handlers locais quando o projeto não exigir `function`.
- Sem ponto e vírgula quando o formatter do projeto assim definir.

## TypeScript

- `strict: true` obrigatório no `tsconfig.json`.
- Preferir **`interface`** sobre `type` para objetos e contratos extensíveis.
- Evitar `enum`; usar `as const` ou union literals.
- Evitar `any`; usar `unknown` + type narrowing.
- Generics e utility types (`Partial`, `Pick`, `Omit`) em vez de duplicação manual.
- Discriminated unions para estado complexo.
- Type guards para null/undefined.
- Props de componentes sempre tipadas com interface explícita.

## React

### Padrões de componente

- Componentes funcionais com hooks.
- Preferir `function Component()` para definição de componentes (padrão RPE/Next.js).
- Lógica reutilizável em **custom hooks** (`use*`).
- Composição sobre herança; compound components para UI complexa.
- Conteúdo estático fora do render.
- Cleanup adequado em `useEffect`.
- Error boundaries e Suspense para loading/erro.
- `React.memo`, `useMemo`, `useCallback` apenas quando há ganho mensurável.
- Code splitting com `React.lazy` / dynamic imports do Next.js.
- Keys estáveis em listas — nunca índice como key.

### Next.js

- **Server Components** por padrão.
- `'use client'` somente para: event listeners, browser APIs, estado cliente, libs client-only.
- Estado de URL via search params quando aplicável.
- Data fetching com padrões Next.js (Server Components, Server Actions).
- Server Actions: erros esperados como valores de retorno, não exceções não tratadas.
- `error.tsx` para error boundaries de rota.

## UI e estilização

- Tailwind para estilos; design tokens e espaçamento consistentes.
- Mobile-first e responsivo.
- Dark mode via CSS variables ou `dark:` do Tailwind.
- shadcn/ui: copiar do registry e customizar no projeto — não tratar como pacote opaco.
- Radix primitives para acessibilidade nativa.

## Estado

| Tipo | Ferramenta |
|------|------------|
| Local simples | `useState` |
| Local complexo | `useReducer` |
| Árvore compartilhada | Context (escopo limitado) |
| Global cliente | Zustand (slices por domínio, selectors, persist quando necessário) |
| Servidor / cache | TanStack Query (query keys hierárquicas, invalidação, optimistic updates) |
| Formulários | React Hook Form |
| URL | React Router ou Next.js routing |

## Formulários e validação

- **Zod** para schemas; mensagens de erro claras e acessíveis.
- **react-hook-form** para estado de formulário.
- `useActionState` com Server Actions no Next.js.

## Performance

- Virtual scrolling para listas grandes.
- Lazy loading de imagens e rotas.
- Bundle analysis periódica.
- Prefetch de dados críticos (TanStack Query).
- Skeleton screens e estados de loading em botões/formulários.
- Above-the-fold primeiro em recursos críticos.

## Tratamento de erros

- Early return para condições de erro.
- Error boundaries em fronteiras de UI.
- `try/catch` em operações async com erros tipados.
- Mensagens amigáveis ao usuário; detalhes técnicos apenas em logs.
- Retry e detecção offline para falhas de rede.
- Validação com feedback por campo.

## Acessibilidade (a11y)

- HTML semântico.
- ARIA apenas quando semântica nativa não bastar.
- Navegação por teclado; `tabIndex`, `aria-label` quando necessário.
- Contraste e hierarquia de headings.
- WCAG 2.1 AA como referência.
- Testes com jest-axe e leitores de tela.

## Testes

- Unitários: utilitários e hooks.
- Componentes: React Testing Library (comportamento, não implementação).
- Integração: fluxos de usuário.
- E2E: Cypress ou Playwright.
- Acessibilidade: jest-axe.

## Segurança

- Validar input no cliente e no servidor.
- Sanitizar contra XSS; CSP quando aplicável.
- HTTPS; CSRF em formulários sensíveis.
- Variáveis de ambiente para segredos — nunca expor no bundle.
- Cookies seguros; validar uploads (tipo, tamanho).

## Commits (quando solicitado)

- Conventional Commits: `feat:`, `fix:`, `chore:`, etc.
- Imperativo, sem ponto final no subject: `feat(auth): add password reset flow`.

## Verificação

Conforme `stack-baseline.mdc` → seção Node.js / TypeScript:

- `npx eslint . --fix`
- `npx prettier --write .`
- `npx tsc --noEmit`
- `npm test`
