# AGENTS.md

Guidelines for coding agents for this repo

## Structure

Personal dotfiles for shell, git, editor, and desktop tooling. Config files live in the repo root and are symlinked into `$HOME` via `install.sh`.

| Path            | Purpose                                      |
| --------------- | -------------------------------------------- |
| `install.sh`    | Symlink dotfiles into home directory         |
| `brew.sh`       | Install CLI and GUI packages                 |
| `npms.sh`       | Install global npm CLIs                      |
| `bin/`          | Helper scripts (git, omarchy, `gen`, etc.)   |
| `.aliases`      | Shell aliases                                |
| `.functions`    | Shell functions                              |
| `.exports`      | Environment variables                        |
| `.gitconfig`    | Git config (local overrides in `*.local`)    |
| `.vscode/`      | VS Code settings and keybindings             |
| `agents/`       | Agent-related scripts                        |
| `tests/`        | Shell script tests                           |

## Rules

- Git commit title format: `emoji [scope] The main change` — example: `✨ [core] Adopt shared account slug tenancy for personal and team`
- Do not add agent trailers to commits (`Made-with:`, `Co-Authored-By: Claude`, Cursor, etc.). Message body only when it adds real context.
- Do not run `git commit` / `git push` unless explicitly requested.
- PR title follows the same format as the git commit title.
- Markdown tables must be auto-aligned (pad columns so pipes line up).
- Do not use superpower or other speculative-driven skills unless explicitly declared.
- If something is unclear, ask questions. Keep everything from design to code as simple as possible.

