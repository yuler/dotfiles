# AGENTS.md

Guidelines for coding agents for this repo

## Structure

Personal dotfiles for shell, git, editor, and desktop tooling. Config files live in the repo root and are symlinked into `$HOME` via `install.sh`.

| Path            | Purpose                                      |
| --------------- | -------------------------------------------- |
| `install.sh`    | Interactive modular installer (using gum)    |
| `install/`      | Modular install scripts (shell, git, etc.)   |
| `brew.sh`       | Install CLI and GUI packages                 |
| `npms.sh`       | Install global npm CLIs                      |
| `bin/`          | Helper scripts (git, omarchy, `gen`, etc.)   |
| `.aliases`      | Shell aliases                                |
| `.functions`    | Shell functions                              |
| `.exports`      | Environment variables                        |
| `.gitconfig`    | Git config (local overrides in `*.local`)    |
| `.vscode/`      | VS Code settings and keybindings             |
| `.config/`      | Hyprland and herdr desktop tooling configs   |
| `agents/`       | Agent scripts and USER.md profile            |
| `tests/`        | Shell script tests                           |

## Rules

- Git commit title format: `emoji [scope] The main change` — example: `✨ [core] Adopt shared account slug tenancy for personal and team`
- Do not add agent trailers to commits (`Made-with:`, `Co-Authored-By: Claude`, Cursor, etc.). Message body only when it adds real context.
- Do not run `git commit` / `git push` unless explicitly requested.
- PR title must follow the same format as git commit title so it can be used directly as the commit title on merge.
- Markdown tables must be auto-aligned (pad columns so pipes line up).
- Do not use superpower or other speculative-driven skills unless explicitly declared.
- If something is unclear, ask questions. Keep everything from design to code as simple as possible.
- Keep each agent-authored file under 5,000 tokens (bytes ÷ 4). Lockfiles and generated code sit outside this limit. Split a file that would cross it by responsibility: one module per concern, helpers and types in a sibling file, and a one-line pointer in the original naming the new path.

