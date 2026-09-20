---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "thunar"
local launcher    = "rofi -show drun -show-icons"
local runner      = "rofi -show run"
local browser     = "brave"
local music       = "spotify"


local mainMod = "SUPER"           -- Sets "Windows" key as main modifier
local secondMod = "SUPER + SHIFT" -- Sets "Windows + Shift" as secondary modifier
local thirdMod = "CTRL + SHIFT"   -- Sets "Ctrl + Shift" as tertiary modifier
local fourthMod = "SUPER + ALT"   -- Sets "Windows + Alt" as quaternary modifier
local fifthMod = "CTRL + ALT"     -- Sets "Windows + Ctrl" as quinary modifier

-- Basics Binds
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(fifthMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(music))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(launcher))
hl.bind(secondMod .. " + Space", hl.dsp.exec_cmd(runner))

-- Screenshot bindings
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot --freeze -m output"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot --freeze -m window"))
hl.bind(secondMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot --freeze -m region"))

-- Theme switcher (pick wallpaper, regenerate colors with matugen)
hl.bind(secondMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/theme-switcher.sh"))

-- Power menu / audio visualizer
hl.bind(mainMod .. " + Escape",
  hl.dsp.exec_cmd("pgrep -x wlogout >/dev/null && pkill -x wlogout || wlogout"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("kitty --class cava -e cava"))
hl.bind(thirdMod .. " + M", hl.dsp.exec_cmd("kitty --class matrix -e unimatrix -i"))


-- Close blueman-manager/pwvucontrol with Escape if one is focused; non_consuming
-- means Escape still reaches whatever app is focused otherwise (e.g. Vim).
hl.bind("Escape", hl.dsp.exec_cmd("~/.config/hypr/scripts/close-overlay-on-escape.sh"),
  { non_consuming = true })

-- Close windows/Hyprland
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(secondMod .. " + C",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + arrow keys
hl.bind(secondMod .. " + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(secondMod .. " + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(secondMod .. " + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(secondMod .. " + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(secondMod .. " + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(secondMod .. " + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(secondMod .. " + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(secondMod .. " + j", hl.dsp.window.move({ direction = "down" }))


hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(secondMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(secondMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(secondMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(secondMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(fourthMod .. " + S", hl.dsp.exec_cmd("hyprlock & systemctl suspend"))
hl.bind(fourthMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(secondMod .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(secondMod .. " + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })


----------------------------
---- SPECIALTY BINDINGS ----
----------------------------

-- 1Password bindings
hl.bind(thirdMod .. " + SPACE", hl.dsp.exec_cmd("1password --quick-access")) -- Open Quick Access (Global search bar)
hl.bind(thirdMod .. " + L", hl.dsp.exec_cmd("1password --lock"))             -- Lock 1Password
