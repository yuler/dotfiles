import os from "node:os"
import type { Plugin } from "@opencode-ai/plugin"

type PermissionAsked = {
  type: "permission.asked"
  properties: {
    id: string
    permission: string
    patterns?: string[]
    metadata?: Record<string, unknown>
  }
}

type QuestionAsked = {
  type: "question.asked"
  properties: { id: string; prompt?: string; title?: string }
}

const MAX_TRACKED = 200

export const OmarchyNotify: Plugin = async ({ $, directory }) => {
  const sent = new Set<string>()

  function track(id: string): boolean {
    if (sent.has(id)) return false
    sent.add(id)
    if (sent.size > MAX_TRACKED) {
      const oldest = sent.values().next().value
      if (oldest !== undefined) sent.delete(oldest)
    }
    return true
  }

  // Clicking the notification runs this command: it selects the tmux pane
  // running opencode for the current project directory (preferring the pane
  // whose process tree actually contains opencode), then focuses the exact
  // foot window carrying that tmux session (resolved via client pid ancestry,
  // never title matching). Source of truth lives in dotfiles/agents/ and is
  // symlinked to ~/.config/opencode/plugins/. Since the #7926
  // security change, `--exec` takes separate argv words (never re-parsed by a
  // shell), must come after the positionals, and does not expand `~` — so the
  // script path has to be absolute.
  const jumpScript = `${os.homedir()}/.config/opencode/plugins/opencode-omarchy-jump.sh`

  async function send(headline: string, body: string) {
    try {
      await $`omarchy notification send --app-name opencode -u normal ${headline} ${body} --exec ${jumpScript} ${directory ?? "."}`
    } catch {
      // Notifications are best-effort; never block the session.
    }
  }

  return {
    event: async ({ event }) => {
      if (event.type === "permission.asked") {
        const p = (event as PermissionAsked).properties
        if (!track(p.id)) return
        const command = p.metadata?.command
        const what =
          typeof command === "string"
            ? command
            : p.permission === "bash" && p.patterns?.length
              ? p.patterns.join("; ")
              : p.permission
        await send("opencode needs approval", what)
      } else if (event.type === "question.asked") {
        const p = (event as QuestionAsked).properties
        if (!track(p.id)) return
        await send("opencode has a question", p.prompt ?? p.title ?? "needs your input")
      }
    },
  }
}
