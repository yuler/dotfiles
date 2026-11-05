-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { omarchy = "walker -m symbols" })

-- Typo: bind on release so Ctrl/Shift are up before typo sends Ctrl+C.
-- (Migrated from Omarchy 3 bindings.conf; dev build path.)
o.bind("CTRL + SHIFT + X", "Typo: correct selection", "/home/yule/Projects/typo/apps/desktop/src-tauri/target/debug/typo --selection", { release = true })
o.bind("CTRL + SHIFT + SPACE", "Typo: quick pick", "/home/yule/Projects/typo/apps/desktop/src-tauri/target/debug/typo --quick-pick", { release = true })

-- Port Manager: SUPER+CTRL+P, same panel as clicking the bar icon.
-- Unbind existing SUPER+CTRL+P (was: Power).
hl.unbind("SUPER + CTRL + P")
o.bind("SUPER + CTRL + P", "Port Manager", "omarchy-shell shell toggle yuler.omaports")

-- Tmux dev sessions: dotfiles override (Hyprland PATH lacks ~/Projects/dotfiles/bin).
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + ALT + RETURN", "Tmux", "$HOME/Projects/dotfiles/bin/omarchy-launch-terminal-tmux")

-- Omasnap: Wayland screenshot + annotation editor.
-- Replace the default PRINT screenshot binding with omasnap.
hl.unbind("PRINT")
hl.unbind("F12")
hl.unbind("ALT + SHIFT + 4")

o.bind("PRINT", "Screenshot", "omasnap")
o.bind("F12", "Screenshot", "omasnap")
o.bind("ALT + SHIFT + 4", "Screenshot", "omasnap")

-- WeChat hides its window on close but keeps running, blocking relaunch.
local function close_window_unless_wechat()
  local w = hl.get_active_window()
  if w and w.class:lower() == "wechat" then
    hl.dispatch(hl.dsp.exec_cmd("omarchy-notification-send -t 2000 'WeChat' 'Cannot close this window with a keyboard shortcut'"))
    return
  end
  hl.dispatch(hl.dsp.window.close())
end

hl.unbind("SUPER + W")
hl.unbind("SUPER + Q")
o.bind("SUPER + W", "Close window", close_window_unless_wechat)
o.bind("SUPER + Q", "Close window", close_window_unless_wechat)

-- Herdr: override Omarchy's launcher so the window gets --app-id=herdr and
-- matches the ^herdr$ float rule (was: tiled foot window).
-- (Same override pattern as SUPER+ALT+RETURN above; dotfiles bin is not on
-- Hyprland's runtime PATH, so bind the absolute path.)
hl.unbind("SUPER + CTRL + RETURN")
o.bind("SUPER + CTRL + RETURN", "Herdr", "$HOME/Projects/dotfiles/bin/omarchy-launch-terminal-herdr")

-- Numpad aliases for the number-row workspace keys. Bound by keycode so
-- NumLock does not matter (KP_1 is a different key from the top-row 1).
-- XKB codes: KP1=87 KP2=88 KP3=89 KP4=83 KP5=84 KP6=85 KP7=79 KP8=80 KP9=81 KP0=90
local numpad_workspace_codes = {
  [1] = 87, [2] = 88, [3] = 89, [4] = 83, [5] = 84,
  [6] = 85, [7] = 79, [8] = 80, [9] = 81, [10] = 90,
}
for workspace, code in pairs(numpad_workspace_codes) do
  local key = "code:" .. code
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end
