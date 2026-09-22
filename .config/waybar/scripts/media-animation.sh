#!/usr/bin/env bash

source "$(dirname "$0")/media-status.sh"
ensure_media_status_watcher

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"
bars=8

# creating "dictionary" to replace char with bar
i=0
while [ $i -lt ${#bar} ]; do
  dict="${dict}s/$i/${bar:$i:1}/g;"
  i=$((i = i + 1))
done

# write cava config
config_file="/tmp/polybar_cava_config"
echo "
[general]
bars = $bars

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
" >$config_file

# read stdout from cava
cava -p $config_file | while read -r line; do
  if [ "$(media_status)" = "Playing" ]; then
    echo $line | sed $dict
  else
    echo ""
  fi
done

