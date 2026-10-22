-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    layout = "dwindle",
  },
})

-- Omasnap: disable animations and screen sharing on its layer surfaces.
hl.layer_rule({
  match = { namespace = "^omasnap$" },
  no_anim = true,
  animation = "none",
  no_screen_share = true,
})

-- Transparent terminal + gaussian blur for scratchpad (herdr/agent).
hl.config({
  decoration = {
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      vibrancy = 0.1696,
      new_optimizations = true,
    },
  },
})

-- Scratchpad seed uses app-id org.omarchy.agent, but actual window here is
-- foot on special:scratchpad, so match the workspace to cover herdr/agent/foot.
o.window({ class = "^org.omarchy.agent$" }, { opacity = "0.96 0.93" })
o.window({ workspace = "special:scratchpad" }, { opacity = "0.96 0.93" })
