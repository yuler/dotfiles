# USER.md

Developer profile and personal runtime preferences for AI agents.

## 1. Identity & Role

- **Name/Handle**: Yule (@yuler)
- **Role**: Full-Stack Engineer & Product Builder
- **Focus**: Web engineering, developer tooling, automated workflows, pragmatic system architecture.
- **Orientation**: High agency, shipping fast with high code maintainability.

## 2. Profile & Stack Familiarity

- **Primary Languages & Runtimes**: TypeScript, JavaScript, Bun, Bash, Node.js.
- **Scripting Preference**: Strongly prefer **TypeScript + Bun** for automation, scratch scripts, and developer tooling. Python is secondary and should only be used when specifically required by existing project code or libraries.

## 3. Working Habits & Scripting Directives

- **Scripting with TypeScript + Bun**:
  - **Preferred Language**: Default to **TypeScript** (`.ts`) whenever writing automation, scratch scripts, or helper tools.
  - **Preferred Runtime**: Use **Bun** for execution (`bun run script.ts` or `bun script.ts`).
  - **Inline Commands**: Prefer `bun -e "..."` over `node -e "..."` or `python3 -c "..."`.
  - **Zero Scaffolding**: Standalone helper scripts should be lightweight:
    - Add `#!/usr/bin/env bun` to executable scripts.
    - Use Bun's native APIs: `Bun.$` for shell command piping, `Bun.file()` / `Bun.write()` for file I/O.
    - Do not generate unnecessary `package.json` or `node_modules` for single-file scripts.
- **Radical Simplicity**:
  - Keep everything from design to code as simple as possible.
  - Avoid speculative abstractions, over-engineering, and boilerplate bloat.
- **Git & Commit Hygiene**:
  - Format commit titles as: `emoji [scope] The main change`.
  - Never add AI trailers to commits (`Made-with:`, `Co-Authored-By: Claude`, Cursor, etc.).
  - PR titles mirror the commit title standard.
- **Direct & Technical Communication**:
  - Be concise and actionable.
  - Do not include conversational filler, flattery, or restatements of obvious facts.

## 4. Precedence & Conflict Resolution

This file (`USER.md`) defines personal developer preferences, while repository-level rules (`AGENTS.md` / `CLAUDE.md`) define project constraints.

| Scope                       | Authority              | Rule                                                                                                        |
| :-------------------------- | :--------------------- | :---------------------------------------------------------------------------------------------------------- |
| **Project Production Code** | Repository `AGENTS.md` | Follow the repo's designated tech stack (e.g. an existing Python service uses Python for production code).    |
| **Auxiliary & Scratch**     | User `USER.md`         | Prefer TypeScript + Bun for ad-hoc scripts, debugging helpers, or temporary tools.                         |
| **Ambiguous / Unspecified** | User `USER.md`         | Default to TypeScript + Bun whenever the repository does not strictly require otherwise.                    |
