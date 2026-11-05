-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Herdr agent toasts with click-to-focus. delivery = "off" in herdr config.toml.
-- Script: ~/Projects/dotfiles/bin/omarchy-herdr-notify
o.launch_on_start("$HOME/Projects/dotfiles/bin/omarchy-herdr-notify >> /tmp/omarchy-herdr-notify.log 2>&1")

-- Auto-switch Rime Chinese → English after 60s keyboard idle.
-- Script: ~/Projects/dotfiles/bin/omarchy-fcitx-idle-english
-- Debug logs: /tmp/fcitx-idle-english.log
-- (Migrated from Omarchy 3 autostart.conf)
o.launch_on_start("$HOME/Projects/dotfiles/bin/omarchy-fcitx-idle-english >> /tmp/fcitx-idle-english.log 2>&1")

-- Login layout startup script.
-- Script: ~/Projects/dotfiles/bin/omarchy-startup-workspaces.sh
o.exec_on_start("$HOME/Projects/dotfiles/bin/omarchy-startup-workspaces.sh")
