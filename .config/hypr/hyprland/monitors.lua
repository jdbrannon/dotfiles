-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
  output   = "DP-1",
  mode     = "2560x1440@165.00Hz",
  position = "0x0",
  scale    = "1",
})

hl.monitor({
  output   = "HDMI-A-1",
  mode     = "2560x1440@60.00Hz",
  position = "2560x0",
  scale    = "1",
})

-- Pin workspaces 1-5 to DP-1 and 6-10 to HDMI-A-1 so mainMod+[0-9] and
-- waybar's per-monitor workspace buttons always agree on which screen a
-- workspace lives on. See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
for i = 1, 5 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = (i == 1), persistent = true })
end
for i = 6, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", default = (i == 6), persistent = true })
end
