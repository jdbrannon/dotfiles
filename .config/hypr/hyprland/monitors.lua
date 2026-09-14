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
