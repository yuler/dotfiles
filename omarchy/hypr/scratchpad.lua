-- Scratchpad (SUPER+S) is herdr-only: full-size tiled panel.
-- Non-herdr windows opened or moved onto the pad are ejected to the current
-- (underlying) workplace, and focus follows them (scratchpad hides via
-- hide_special_on_workspace_change).

local PAD = "special:scratchpad"
local HERDR_LAUNCH = os.getenv("HOME") .. "/Projects/dotfiles/bin/omarchy-launch-terminal-herdr"

hl.workspace_rule({
  workspace = PAD,
  layout = "dwindle",
  gaps_in = 0,
  gaps_out = 0,
  no_border = true,
})

local function is_herdr(window)
  if not window then
    return false
  end
  local class = (window.class or window.initialClass or ""):lower()
  return class == "herdr"
end

local function on_scratchpad(window)
  local ws = window and window.workspace
  return ws and ws.name == PAD
end

local function seed_herdr()
  hl.exec_cmd(HERDR_LAUNCH, { workspace = PAD, silent = true })
end

local function seed_if_empty(workspace)
  if workspace and workspace.name == PAD and workspace.is_empty then
    seed_herdr()
  end
end

hl.on("workspace.created", seed_if_empty)

hl.on("workspace.special_active", function(ws)
  seed_if_empty(ws)
end)

local function settle_herdr(window)
  if not window or not window.address or not is_herdr(window) or not on_scratchpad(window) then
    return
  end
  local addr = "address:" .. window.address
  -- Override the global float+center rule so herdr fills the pad as a tile.
  if window.floating then
    hl.dispatch(hl.dsp.window.float({ action = "off", window = addr }))
  end
  -- 1 = fullscreen, 2 = maximized (Hyprland); clear both so dwindle can fill the pad.
  if (window.fullscreen or 0) ~= 0 then
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset", window = addr }))
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", window = addr }))
  end
end

local function eject(window)
  if not window or not window.address then
    return
  end
  if is_herdr(window) then
    settle_herdr(window)
    return
  end
  if not on_scratchpad(window) then
    return
  end

  -- Prefer the normal workplace under the pad (monitor.active_workspace),
  -- not previous_per_monitor.
  local mon = hl.get_active_monitor()
  local current = mon and mon.active_workspace
  local dest = (current and current.id and current.id > 0) and tostring(current.id) or "m~0"

  hl.dispatch(hl.dsp.window.move({
    workspace = dest,
    follow = true,
    window = "address:" .. window.address,
  }))
end

-- Let the window finish mapping / landing on the pad before settling / ejecting.
local function settle_soon(window)
  hl.timer(function()
    local live = window.address and hl.get_window("address:" .. window.address)
    eject(live or window)
  end, { type = "oneshot", timeout = 1 })
end

hl.on("window.open", settle_soon)
hl.on("window.move_to_workspace", settle_soon)
