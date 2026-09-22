#!/usr/bin/env bash

playerctl -p playerctld metadata --format '{{duration(position)}}/{{duration(mpris:length)}}' 2>/dev/null
