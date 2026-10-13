-- 软件配置文件。
-- 只给 Omarchy（欧马奇）用，并且只在这台 Linux 电脑上用。
-- 改完重新加载：hyprctl reload
--
-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- WeChat: start at a ~700px chat column in the scrolling layout (workspace 3).
o.window("wechat", { scrolling_width = 0.37 })

-- WeChat popups (image/video preview, etc.): float them instead of tiling
-- them. `negative:` passes when the regex fails, so the main "Weixin"
-- window keeps tiling.
o.window({ class = "^wechat$", title = "negative:^Weixin$" }, { float = true })

-- WeChatAppEx (mini programs, embedded pages) opens with an empty class and
-- title "WeChat", so the class=wechat rule above never matches it.
o.window({ class = "^$", title = "^WeChat$", xwayland = true }, { float = true, center = true })

-- Magpie's quick panel is placed by magpie itself (named rule "magpie-panel":
-- pinned under the bar, no border, no shadow). An anonymous float rule is
-- applied after that and turns the panel into a normal floating window.
o.window({ class = "^magpie$", title = "^magpie$" }, { float = true, center = true })

-- Herdr: always float centered, so opening/closing it never shifts the
-- tiling layout. Herdr runs inside foot (class=foot like every terminal),
-- so the launcher must give it a dedicated app-id:
--   bin/omarchy-launch-terminal-herdr  (SUPER + CTRL + RETURN, see bindings.lua)
-- Plain `foot -e herdr` windows (e.g. the login workspace) stay tiled.
o.window("^herdr$", { float = true })
o.window("^herdr$", { center = true })
o.window("^herdr$", { size = { 1400, 900 } })
